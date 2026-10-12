package http_h

import (
	"net/http"

	"github.com/DanielRasho/Thesis/internal/services/sessions_s"
	"github.com/DanielRasho/Thesis/utils"
)

// PostLogout ends the session and clears the cookie. Idempotent: it also
// answers 204 without a session.
//
//	POST /auth/logout -> 204 + Set-Cookie (expired)
func PostLogout(sessions *sessions_s.SessionService) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if cookie, err := r.Cookie(sessions_s.CookieName); err == nil && cookie.Value != "" {
			if err := sessions.Delete(r.Context(), cookie.Value); err != nil {
				utils.WriteError(w, r, err)
				return
			}
		}

		http.SetCookie(w, sessions.ExpiredCookie())
		w.WriteHeader(http.StatusNoContent)
	}
}
