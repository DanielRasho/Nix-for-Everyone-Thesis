package http_h

import (
	"net/http"
	"time"

	"github.com/DanielRasho/Thesis/internal/services/survey_s"
	"github.com/DanielRasho/Thesis/internal/services/users_s"
	"github.com/DanielRasho/Thesis/internal/storage/survey_db"
	"github.com/DanielRasho/Thesis/utils"
	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

// participantView is a participant as the admin panel sees it.
type participantView struct {
	ID        pgtype.UUID     `json:"id"`
	Username  string          `json:"username"`
	CreatedAt time.Time       `json:"createdAt"`
	Steps     []survey_s.Step `json:"steps"`
}

func newParticipantView(user survey_db.User, steps []survey_s.Step) participantView {
	return participantView{
		ID:        user.ID,
		Username:  user.Username,
		CreatedAt: user.CreatedAt.Time,
		Steps:     steps,
	}
}

// GetParticipants answers every participant with their progress.
//
//	GET /admin/participants -> 200 { participants }
func GetParticipants(users *users_s.UserService, surveys *survey_s.SurveyService) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		participants, err := users.ListParticipants(r.Context())
		if err != nil {
			utils.WriteError(w, r, err)
			return
		}
		steps, err := surveys.AllParticipantSteps(r.Context())
		if err != nil {
			utils.WriteError(w, r, err)
			return
		}

		views := make([]participantView, 0, len(participants))
		for _, p := range participants {
			userSteps, ok := steps[p.ID]
			if !ok {
				userSteps = surveys.StepsWithoutProgress()
			}
			views = append(views, newParticipantView(p, userSteps))
		}

		utils.WriteJSON(w, r, http.StatusOK, map[string]any{"participants": views})
	}
}

// idParam parses the {id} URL parameter, failing with 400.
func idParam(r *http.Request) (pgtype.UUID, error) {
	raw := chi.URLParam(r, "id")
	id, ok := utils.ParseUUID(raw)
	if !ok {
		return pgtype.UUID{}, utils.Reject(utils.InvalidID, "id %q is not a UUID", raw)
	}
	return id, nil
}
