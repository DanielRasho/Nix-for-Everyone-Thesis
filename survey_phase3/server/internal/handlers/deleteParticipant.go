package http_h

import (
	"net/http"

	"github.com/DanielRasho/Thesis/internal/services/users_s"
	"github.com/DanielRasho/Thesis/utils"
)

// DeleteParticipant deletes a participant and all their answers.
//
//	DELETE /admin/participants/{id} -> 204
func DeleteParticipant(users *users_s.UserService) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id, err := idParam(r)
		if err != nil {
			utils.WriteError(w, r, err)
			return
		}

		if err := users.DeleteParticipant(r.Context(), id); err != nil {
			utils.WriteError(w, r, err)
			return
		}

		w.WriteHeader(http.StatusNoContent)
	}
}
