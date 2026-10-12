package http_h

import (
	"encoding/json"
	"net/http"

	"github.com/DanielRasho/Thesis/internal/services/results_s"
	"github.com/DanielRasho/Thesis/utils"
	"github.com/go-playground/validator/v10"
)

type gradeBody struct {
	UserID     string       `json:"userId" validate:"required"`
	QuestionID string       `json:"questionId" validate:"required"`
	IsCorrect  nullableBool `json:"isCorrect"`
}

// nullableBool tells apart a missing field from an explicit null.
type nullableBool struct {
	Set   bool
	Value *bool // nil when null
}

func (b *nullableBool) UnmarshalJSON(data []byte) error {
	b.Set = true
	if string(data) == "null" {
		b.Value = nil
		return nil
	}
	return json.Unmarshal(data, &b.Value)
}

// PutGrading sets the grade of a free_code answer: true, false, or null to
// clear it.
//
//	PUT /admin/grading { userId, questionId, isCorrect } -> 204
func PutGrading(validate *validator.Validate, results *results_s.ResultsService) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var body gradeBody
		if err := utils.DecodeJSON(w, r, validate, &body); err != nil {
			utils.WriteError(w, r, err)
			return
		}

		userID, ok := utils.ParseUUID(body.UserID)
		fields := map[string]string{}
		if !ok {
			fields["userId"] = "must be a valid UUID"
		}
		if !body.IsCorrect.Set {
			fields["isCorrect"] = "is required (true, false or null)"
		}
		if len(fields) > 0 {
			utils.WriteError(w, r, utils.RejectFields(utils.InvalidFields, fields))
			return
		}

		if err := results.Grade(r.Context(), userID, body.QuestionID, body.IsCorrect.Value); err != nil {
			utils.WriteError(w, r, err)
			return
		}

		w.WriteHeader(http.StatusNoContent)
	}
}
