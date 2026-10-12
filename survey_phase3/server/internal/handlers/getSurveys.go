package http_h

import (
	"net/http"

	"github.com/DanielRasho/Thesis/internal/services/survey_s"
	"github.com/DanielRasho/Thesis/utils"
)

// GetSurveys answers the surveys a participant can be assigned.
//
//	GET /admin/surveys -> 200 { surveys: [{ id, title }] }
func GetSurveys(surveys *survey_s.SurveyService) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		utils.WriteJSON(w, r, http.StatusOK, map[string]any{"surveys": surveys.Surveys()})
	}
}
