package http_h

import (
	"net/http"

	"github.com/DanielRasho/Thesis/utils"
)

// NotFound answers routes that don't exist, with the usual error body.
func NotFound(w http.ResponseWriter, r *http.Request) {
	utils.WriteError(w, r, utils.Reject(utils.NotFound, "no route %s %s", r.Method, r.URL.Path))
}

// MethodNotAllowed answers routes that exist, but not with this method.
func MethodNotAllowed(w http.ResponseWriter, r *http.Request) {
	utils.WriteError(w, r, utils.Reject(utils.MethodNotAllowed, "route %s does not accept %s", r.URL.Path, r.Method))
}
