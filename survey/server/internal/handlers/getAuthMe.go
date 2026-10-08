package http_h

import (
	"net/http"

	"github.com/DanielRasho/Thesis/internal/middlewares"
	"github.com/DanielRasho/Thesis/utils"
)

// GetAuthMe answers the logged in user (behind middlewares.RequireUser).
//
//	GET /auth/me -> 200 { user }
func GetAuthMe(w http.ResponseWriter, r *http.Request) {
	user, _ := middlewares.UserFrom(r.Context())
	utils.WriteJSON(w, r, http.StatusOK, map[string]any{"user": user})
}
