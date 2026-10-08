package users_s

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"time"

	"github.com/DanielRasho/Thesis/internal/storage/survey_db"
	"github.com/DanielRasho/Thesis/utils"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/rs/zerolog/log"
	"golang.org/x/crypto/bcrypt"
)

// Postgres error code of a UNIQUE constraint violation.
const uniqueViolation = "23505"

// User is the public view of an account.
type User struct {
	ID       pgtype.UUID        `json:"id"`
	Username string             `json:"username"`
	Role     survey_db.UserRole `json:"role"`
}

type UserService struct {
	DBClient  *pgxpool.Pool
	DBQueries *survey_db.Queries
}

// BootstrapAdmin creates the admin account, or updates its password and role.
// On a fresh volume Postgres runs the init scripts and then restarts once, so
// the DB may not accept connections yet: it retries with backoff until timeout.
func (s *UserService) BootstrapAdmin(ctx context.Context, username, password string, timeout time.Duration) error {
	hash, err := hashPassword(password)
	if err != nil {
		return err
	}

	deadline := time.Now().Add(timeout)
	wait := 500 * time.Millisecond
	for attempt := 1; ; attempt++ {
		attemptCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
		err := s.DBQueries.UpsertAdmin(attemptCtx, survey_db.UpsertAdminParams{
			Username:     username,
			PasswordHash: hash,
		})
		cancel()
		if err == nil {
			return nil
		}
		if time.Now().Add(wait).After(deadline) {
			return fmt.Errorf("database not reachable after %d attempts: %w", attempt, err)
		}

		log.Warn().Err(err).Int("attempt", attempt).Dur("retryIn", wait).Msg("Database not ready, retrying admin bootstrap")
		time.Sleep(wait)
		wait = min(wait*2, 5*time.Second)
	}
}

// Authenticate checks a username and password. Failures are 401 for the client,
// the log reason says which part was wrong.
func (s *UserService) Authenticate(ctx context.Context, username, password string) (User, error) {
	user, err := s.DBQueries.GetUserByUsername(ctx, username)
	if errors.Is(err, pgx.ErrNoRows) {
		// Compare anyway, so unknown usernames take as long as wrong passwords.
		bcrypt.CompareHashAndPassword(dummyHash(), []byte(password))
		return User{}, utils.Reject(utils.WrongCredentials, "unknown username %q", username)
	}
	if err != nil {
		return User{}, fmt.Errorf("getting user %q: %w", username, err)
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password)); err != nil {
		return User{}, utils.Reject(utils.WrongCredentials, "wrong password for %q", username)
	}

	return User{ID: user.ID, Username: user.Username, Role: user.Role}, nil
}

// CreateParticipant creates a participant and their survey assignments (in the
// given order) in one transaction. Returns the generated password, the only
// time it exists in clear text.
func (s *UserService) CreateParticipant(ctx context.Context, username string, surveyOrder []string) (survey_db.User, string, error) {
	password, err := GeneratePassword()
	if err != nil {
		return survey_db.User{}, "", err
	}
	hash, err := hashPassword(password)
	if err != nil {
		return survey_db.User{}, "", err
	}

	var user survey_db.User
	err = pgx.BeginFunc(ctx, s.DBClient, func(tx pgx.Tx) error {
		queries := s.DBQueries.WithTx(tx)

		var err error
		user, err = queries.CreateUser(ctx, survey_db.CreateUserParams{
			Username:     username,
			PasswordHash: hash,
			Role:         survey_db.UserRoleParticipant,
		})
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == uniqueViolation {
			return utils.Reject(utils.UsernameExists, "username %q already exists", username)
		}
		if err != nil {
			return fmt.Errorf("creating user %q: %w", username, err)
		}

		for i, survey := range surveyOrder {
			err := queries.CreateAssignment(ctx, survey_db.CreateAssignmentParams{
				UserID:   user.ID,
				Survey:   survey,
				Position: int16(i + 1),
			})
			if err != nil {
				return fmt.Errorf("assigning survey %q to %q: %w", survey, username, err)
			}
		}
		return nil
	})
	if err != nil {
		return survey_db.User{}, "", err
	}

	return user, password, nil
}

// RegeneratePassword sets a new random password for a participant and logs
// them out of every device.
func (s *UserService) RegeneratePassword(ctx context.Context, id pgtype.UUID) (string, error) {
	password, err := GeneratePassword()
	if err != nil {
		return "", err
	}
	hash, err := hashPassword(password)
	if err != nil {
		return "", err
	}

	err = pgx.BeginFunc(ctx, s.DBClient, func(tx pgx.Tx) error {
		queries := s.DBQueries.WithTx(tx)

		updated, err := queries.UpdateParticipantPassword(ctx, survey_db.UpdateParticipantPasswordParams{
			PasswordHash: hash,
			ID:           id,
		})
		if err != nil {
			return fmt.Errorf("updating password of %s: %w", id, err)
		}
		if updated == 0 {
			return utils.Reject(utils.ParticipantNotFound, "participant %s does not exist", id)
		}

		if err := queries.DeleteUserSessions(ctx, id); err != nil {
			return fmt.Errorf("deleting sessions of %s: %w", id, err)
		}
		return nil
	})
	if err != nil {
		return "", err
	}

	return password, nil
}

// DeleteParticipant deletes a participant with all their data (sessions,
// assignments, answers and times cascade). Admins cannot be deleted.
func (s *UserService) DeleteParticipant(ctx context.Context, id pgtype.UUID) error {
	deleted, err := s.DBQueries.DeleteParticipant(ctx, id)
	if err != nil {
		return fmt.Errorf("deleting participant %s: %w", id, err)
	}
	if deleted == 0 {
		return utils.Reject(utils.ParticipantNotFound, "participant %s does not exist", id)
	}
	return nil
}

// ListParticipants returns every participant, sorted by username.
func (s *UserService) ListParticipants(ctx context.Context) ([]survey_db.User, error) {
	users, err := s.DBQueries.ListParticipants(ctx)
	if err != nil {
		return nil, fmt.Errorf("listing participants: %w", err)
	}
	return users, nil
}

func hashPassword(password string) (string, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return "", fmt.Errorf("hashing password: %w", err)
	}
	return string(hash), nil
}

// dummyHash is compared against when the username doesn't exist.
var dummyHash = sync.OnceValue(func() []byte {
	hash, _ := bcrypt.GenerateFromPassword([]byte("not a real password"), bcrypt.DefaultCost)
	return hash
})
