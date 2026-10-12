package http_h

import (
	"net/http"

	"github.com/DanielRasho/Thesis/internal/middlewares"
	"github.com/DanielRasho/Thesis/internal/services/survey_s"
	"github.com/DanielRasho/Thesis/utils"
)

// GetRoadmap answers the steps of the logged in participant: background, then
// their surveys in order.
//
//	GET /me/roadmap -> 200 { steps }
func GetRoadmap(surveys *survey_s.SurveyService) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		user, _ := middlewares.UserFrom(r.Context())

		steps, err := surveys.Roadmap(r.Context(), user.ID)
		if err != nil {
			utils.WriteError(w, r, err)
			return
		}

		utils.WriteJSON(w, r, http.StatusOK, map[string]any{"steps": steps})
	}
}
