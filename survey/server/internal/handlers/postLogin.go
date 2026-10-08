package http_h

import (
	"net/http"

	"github.com/DanielRasho/Thesis/internal/services/sessions_s"
	"github.com/DanielRasho/Thesis/internal/services/users_s"
	"github.com/DanielRasho/Thesis/utils"
	"github.com/go-playground/validator/v10"
)

type loginBody struct {
	Username string `json:"username" validate:"required"`
	Password string `json:"password" validate:"required"`
}

// PostLogin checks the credentials and starts a session (cookie).
//
//	POST /auth/login { username, password } -> 200 { user } + Set-Cookie
func PostLogin(validate *validator.Validate, users *users_s.UserService, sessions *sessions_s.SessionService) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var body loginBody
		if err := utils.DecodeJSON(w, r, validate, &body); err != nil {
			utils.WriteError(w, r, err)
			return
		}

		user, err := users.Authenticate(r.Context(), body.Username, body.Password)
		if err != nil {
			utils.WriteError(w, r, err)
			return
		}

		// Replace the previous session of this browser, if any.
		if cookie, err := r.Cookie(sessions_s.CookieName); err == nil && cookie.Value != "" {
			if err := sessions.Delete(r.Context(), cookie.Value); err != nil {
				utils.WriteError(w, r, err)
				return
			}
		}

		token, expiresAt, err := sessions.Create(r.Context(), user.ID)
		if err != nil {
			utils.WriteError(w, r, err)
			return
		}

		utils.RequestLogFrom(r.Context()).Username = user.Username
		http.SetCookie(w, sessions.Cookie(token, expiresAt))
		utils.WriteJSON(w, r, http.StatusOK, map[string]any{"user": user})
	}
}
