package http_h

import (
	"fmt"
	"net/http"
	"time"

	"github.com/DanielRasho/Thesis/internal/services/results_s"
	"github.com/DanielRasho/Thesis/utils"
)

// GetExportCode downloads every free_code answer as a zip, one folder per
// participant and one file per question: <username>/<questionId>.<nix|ts>.
//
//	GET /admin/export-code.zip -> 200 application/zip attachment
func GetExportCode(results *results_s.ResultsService) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		data, err := results.ExportCode(r.Context())
		if err != nil {
			utils.WriteError(w, r, err)
			return
		}

		filename := fmt.Sprintf("nixty-survey-code-%s.zip", time.Now().UTC().Format("2006-01-02"))
		w.Header().Set("Content-Type", "application/zip")
		w.Header().Set("Content-Disposition", fmt.Sprintf("attachment; filename=%q", filename))
		w.WriteHeader(http.StatusOK)
		w.Write(data)
	}
}
