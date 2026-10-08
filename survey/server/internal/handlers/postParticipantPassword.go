package http_h

import (
	"net/http"

	"github.com/DanielRasho/Thesis/internal/services/users_s"
	"github.com/DanielRasho/Thesis/utils"
)

// PostParticipantPassword generates a new password for a participant and logs
// them out everywhere. The password is answered only here.
//
//	POST /admin/participants/{id}/password -> 200 { password }
func PostParticipantPassword(users *users_s.UserService) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id, err := idParam(r)
		if err != nil {
			utils.WriteError(w, r, err)
			return
		}

		password, err := users.RegeneratePassword(r.Context(), id)
		if err != nil {
			utils.WriteError(w, r, err)
			return
		}

		utils.WriteJSON(w, r, http.StatusOK, map[string]any{"password": password})
	}
}
