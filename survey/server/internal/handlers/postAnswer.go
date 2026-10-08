package http_h

import (
	"net/http"

	"github.com/DanielRasho/Thesis/internal/middlewares"
	"github.com/DanielRasho/Thesis/internal/services/survey_s"
	"github.com/DanielRasho/Thesis/utils"
	"github.com/go-playground/validator/v10"
)

// PostAnswer stores the answer to the current question of a step and answers
// the next screen of that step.
//
//	POST /me/answers Answer -> 200 Current
func PostAnswer(validate *validator.Validate, surveys *survey_s.SurveyService) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		user, _ := middlewares.UserFrom(r.Context())

		var body survey_s.Answer
		if err := utils.DecodeJSON(w, r, validate, &body); err != nil {
			utils.WriteError(w, r, err)
			return
		}

		current, err := surveys.Answer(r.Context(), user.ID, body)
		if err != nil {
			utils.WriteError(w, r, err)
			return
		}

		utils.WriteJSON(w, r, http.StatusOK, current)
	}
}
