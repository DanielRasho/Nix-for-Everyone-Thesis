package http_h

import (
	"net/http"
	"slices"
	"strings"

	"github.com/DanielRasho/Thesis/internal/services/survey_s"
	"github.com/DanielRasho/Thesis/internal/services/users_s"
	"github.com/DanielRasho/Thesis/utils"
	"github.com/go-playground/validator/v10"
)

type createParticipantBody struct {
	Username    string   `json:"username" validate:"required,username"`
	SurveyOrder []string `json:"surveyOrder" validate:"required"`
}

// PostParticipant creates a participant with their surveys in the given order
// (the order is their group). The password is answered only here.
//
//	POST /admin/participants { username, surveyOrder } -> 201 { participant, password }
func PostParticipant(validate *validator.Validate, users *users_s.UserService, surveys *survey_s.SurveyService) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var body createParticipantBody
		if err := utils.DecodeJSON(w, r, validate, &body); err != nil {
			utils.WriteError(w, r, err)
			return
		}

		// Every survey exactly once.
		ids := make([]string, 0, len(surveys.Surveys()))
		for _, s := range surveys.Surveys() {
			ids = append(ids, s.ID)
		}
		order := slices.Clone(body.SurveyOrder)
		slices.Sort(order)
		if !slices.Equal(order, ids) {
			utils.WriteError(w, r, utils.RejectFields(utils.InvalidFields, map[string]string{
				"surveyOrder": "must contain each survey exactly once: " + strings.Join(ids, ", "),
			}))
			return
		}

		user, password, err := users.CreateParticipant(r.Context(), body.Username, body.SurveyOrder)
		if err != nil {
			utils.WriteError(w, r, err)
			return
		}

		steps, err := surveys.ParticipantSteps(r.Context(), user.ID)
		if err != nil {
			utils.WriteError(w, r, err)
			return
		}

		utils.WriteJSON(w, r, http.StatusCreated, map[string]any{
			"participant": newParticipantView(user, steps),
			"password":    password,
		})
	}
}
