package http_h

import (
	"net/http"

	"github.com/DanielRasho/Thesis/internal/middlewares"
	"github.com/DanielRasho/Thesis/internal/services/survey_s"
	"github.com/DanielRasho/Thesis/utils"
	"github.com/go-chi/chi/v5"
)

// GetCurrent answers the current question of a step (null once finished) and
// marks the survey as started.
//
//	GET /me/steps/{stepId}/current -> 200 Current
func GetCurrent(surveys *survey_s.SurveyService) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		user, _ := middlewares.UserFrom(r.Context())

		current, err := surveys.Current(r.Context(), user.ID, chi.URLParam(r, "stepId"))
		if err != nil {
			utils.WriteError(w, r, err)
			return
		}

		utils.WriteJSON(w, r, http.StatusOK, current)
	}
}
