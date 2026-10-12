package http_h

import (
	"net/http"

	"github.com/DanielRasho/Thesis/internal/services/results_s"
	"github.com/DanielRasho/Thesis/utils"
)

// GetGrading answers every free_code answer, graded or not.
//
//	GET /admin/grading -> 200 { answers: GradingAnswer[] }
func GetGrading(results *results_s.ResultsService) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		answers, err := results.GradingAnswers(r.Context())
		if err != nil {
			utils.WriteError(w, r, err)
			return
		}

		utils.WriteJSON(w, r, http.StatusOK, map[string]any{"answers": answers})
	}
}
