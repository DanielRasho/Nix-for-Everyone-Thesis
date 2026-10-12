package middlewares

import (
	"context"
	"net/http"

	"github.com/DanielRasho/Thesis/internal/services/sessions_s"
	"github.com/DanielRasho/Thesis/internal/services/users_s"
	"github.com/DanielRasho/Thesis/internal/storage/survey_db"
	"github.com/DanielRasho/Thesis/utils"
)

type sessionKey struct{}

// session is what the Session middleware found about the request.
type session struct {
	user     users_s.User
	loggedIn bool
	reason   string // why there is no user, for the logs
}

// Session resolves the session cookie into the logged in user and puts it in
// the request context. It never rejects a request by itself, the guards
// RequireUser and RequireRole do.
func Session(sessions *sessions_s.SessionService) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			current := session{reason: "no session cookie"}

			if cookie, err := r.Cookie(sessions_s.CookieName); err == nil && cookie.Value != "" {
				user, ok, err := sessions.User(r.Context(), cookie.Value)
				if err != nil {
					utils.WriteError(w, r, err)
					return
				}
				if ok {
					current = session{user: user, loggedIn: true}
					utils.RequestLogFrom(r.Context()).Username = user.Username
				} else {
					current.reason = "session is invalid or expired"
				}
			}

			next.ServeHTTP(w, r.WithContext(context.WithValue(r.Context(), sessionKey{}, current)))
		})
	}
}

// UserFrom returns the logged in user of the request.
func UserFrom(ctx context.Context) (users_s.User, bool) {
	current, _ := ctx.Value(sessionKey{}).(session)
	return current.user, current.loggedIn
}

// RequireUser answers 401 when there is no valid session.
func RequireUser(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		current, _ := r.Context().Value(sessionKey{}).(session)
		if !current.loggedIn {
			reason := current.reason
			if reason == "" {
				reason = "session middleware is not installed"
			}
			utils.WriteError(w, r, utils.Reject(utils.Unauthorized, "%s", reason))
			return
		}
		next.ServeHTTP(w, r)
	})
}

// RequireRole answers 401 when there is no valid session and 403 when the
// user has another role.
func RequireRole(role survey_db.UserRole) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return RequireUser(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			user, _ := UserFrom(r.Context())
			if user.Role != role {
				utils.WriteError(w, r, utils.Reject(utils.Forbidden, "route is only for %s users, %q is %s", role, user.Username, user.Role))
				return
			}
			next.ServeHTTP(w, r)
		}))
	}
}
