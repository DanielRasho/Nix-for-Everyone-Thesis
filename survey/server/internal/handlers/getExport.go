package http_h

import (
	"fmt"
	"net/http"
	"time"

	"github.com/DanielRasho/Thesis/internal/services/results_s"
	"github.com/DanielRasho/Thesis/utils"
)

// GetExport downloads every answer (with times) as CSV, in long format.
//
//	GET /admin/export.csv -> 200 text/csv attachment
func GetExport(results *results_s.ResultsService) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		data, err := results.ExportCSV(r.Context())
		if err != nil {
			utils.WriteError(w, r, err)
			return
		}

		filename := fmt.Sprintf("nixty-survey-answers-%s.csv", time.Now().UTC().Format("2006-01-02"))
		w.Header().Set("Content-Type", "text/csv; charset=utf-8")
		w.Header().Set("Content-Disposition", fmt.Sprintf("attachment; filename=%q", filename))
		w.WriteHeader(http.StatusOK)
		w.Write(data)
	}
}
