package sessions_s

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"errors"
	"fmt"
	"net/http"
	"time"

	"github.com/DanielRasho/Thesis/internal/services/users_s"
	"github.com/DanielRasho/Thesis/internal/storage/survey_db"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

// CookieName is the HttpOnly cookie that carries the session token.
const CookieName = "survey_session"

// Random bytes of a session token (base64url in the cookie).
const tokenBytes = 32

// SessionService handles login sessions. The token only lives in the cookie,
// the DB stores its sha256, so a leaked DB can't be used to log in.
type SessionService struct {
	DBClient     *pgxpool.Pool
	DBQueries    *survey_db.Queries
	TTL          time.Duration // how long a login lasts
	CookieSecure bool          // send the cookie only over HTTPS
}

// Create starts a session for the user and returns its token.
func (s *SessionService) Create(ctx context.Context, userID pgtype.UUID) (string, time.Time, error) {
	raw := make([]byte, tokenBytes)
	if _, err := rand.Read(raw); err != nil {
		return "", time.Time{}, fmt.Errorf("generating session token: %w", err)
	}
	token := base64.RawURLEncoding.EncodeToString(raw)
	expiresAt := time.Now().Add(s.TTL)

	err := s.DBQueries.CreateSession(ctx, survey_db.CreateSessionParams{
		TokenHash: hashToken(token),
		UserID:    userID,
		ExpiresAt: pgtype.Timestamptz{Time: expiresAt, Valid: true},
	})
	if err != nil {
		return "", time.Time{}, fmt.Errorf("creating session: %w", err)
	}
	return token, expiresAt, nil
}

// User returns the user of a session. ok is false if the token is unknown or
// expired.
func (s *SessionService) User(ctx context.Context, token string) (user users_s.User, ok bool, err error) {
	row, err := s.DBQueries.GetSessionUser(ctx, hashToken(token))
	if errors.Is(err, pgx.ErrNoRows) {
		return users_s.User{}, false, nil
	}
	if err != nil {
		return users_s.User{}, false, fmt.Errorf("getting session user: %w", err)
	}
	return users_s.User{ID: row.ID, Username: row.Username, Role: row.Role}, true, nil
}

// Delete ends a session. Unknown tokens are ignored.
func (s *SessionService) Delete(ctx context.Context, token string) error {
	if err := s.DBQueries.DeleteSession(ctx, hashToken(token)); err != nil {
		return fmt.Errorf("deleting session: %w", err)
	}
	return nil
}

// Cookie returns the session cookie for a token.
func (s *SessionService) Cookie(token string, expiresAt time.Time) *http.Cookie {
	return &http.Cookie{
		Name:     CookieName,
		Value:    token,
		Path:     "/",
		Expires:  expiresAt,
		MaxAge:   int(time.Until(expiresAt).Seconds()),
		HttpOnly: true,
		Secure:   s.CookieSecure,
		SameSite: http.SameSiteLaxMode,
	}
}

// ExpiredCookie returns a cookie that removes the session cookie from the browser.
func (s *SessionService) ExpiredCookie() *http.Cookie {
	return &http.Cookie{
		Name:     CookieName,
		Value:    "",
		Path:     "/",
		Expires:  time.Unix(0, 0),
		MaxAge:   -1,
		HttpOnly: true,
		Secure:   s.CookieSecure,
		SameSite: http.SameSiteLaxMode,
	}
}

func hashToken(token string) []byte {
	sum := sha256.Sum256([]byte(token))
	return sum[:]
}
