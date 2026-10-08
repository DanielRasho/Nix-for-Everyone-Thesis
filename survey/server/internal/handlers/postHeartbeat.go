package http_h

import (
	"net/http"

	"github.com/DanielRasho/Thesis/internal/middlewares"
	"github.com/DanielRasho/Thesis/internal/services/survey_s"
	"github.com/DanielRasho/Thesis/utils"
	"github.com/go-playground/validator/v10"
)

type heartbeatBody struct {
	QuestionID string `json:"questionId" validate:"required"`
}

// PostHeartbeat records that the participant is still on the current question.
//
//	POST /me/heartbeat { questionId } -> 204
func PostHeartbeat(validate *validator.Validate, surveys *survey_s.SurveyService) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		user, _ := middlewares.UserFrom(r.Context())

		var body heartbeatBody
		if err := utils.DecodeJSON(w, r, validate, &body); err != nil {
			utils.WriteError(w, r, err)
			return
		}

		if err := surveys.Heartbeat(r.Context(), user.ID, body.QuestionID); err != nil {
			utils.WriteError(w, r, err)
			return
		}

		w.WriteHeader(http.StatusNoContent)
	}
}
