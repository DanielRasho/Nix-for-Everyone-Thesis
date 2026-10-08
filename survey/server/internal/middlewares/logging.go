package middlewares

import (
	"fmt"
	"net/http"
	"runtime/debug"
	"strings"
	"time"

	"github.com/DanielRasho/Thesis/utils"
	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

// Logging writes exactly one log line per request, once it is answered:
// method, route, status, duration and user (if logged in).
//
//   - 2xx/3xx at info.
//   - 4xx at warn, with the reason recorded by utils.WriteError.
//   - 5xx at error, with the underlying error.
//
// It also recovers from panics (answering 500), so it must be the first
// middleware of the router.
func Logging(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		info := &utils.RequestLog{}
		r = r.WithContext(utils.WithRequestLog(r.Context(), info))
		ww := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}

		defer func() {
			if rec := recover(); rec != nil {
				if rec == http.ErrAbortHandler {
					panic(rec) // the server aborts the response on purpose
				}
				err := fmt.Errorf("panic: %v\n%s", rec, debug.Stack())
				if ww.wroteHeader {
					info.Err = err
				} else {
					utils.WriteError(ww, r, err)
				}
			}
			logRequest(r, ww.statusCode, time.Since(start), info)
		}()

		next.ServeHTTP(ww, r)
	})
}

func logRequest(r *http.Request, status int, duration time.Duration, info *utils.RequestLog) {
	// Pattern of the matched route (e.g. /me/steps/{stepId}/current), so
	// lines of the same route can be grouped. Requests rejected before a route
	// matched (unknown routes, guards of /me/* and /admin/*) log the path.
	route := r.URL.Path
	if rctx := chi.RouteContext(r.Context()); rctx != nil {
		if pattern := rctx.RoutePattern(); pattern != "" && !strings.HasSuffix(pattern, "*") {
			route = pattern
		}
	}

	var event *zerolog.Event
	switch {
	case status >= 500:
		event = log.Error().Err(info.Err)
	case status >= 400:
		reason := info.Reason
		if reason == "" {
			reason = http.StatusText(status)
		}
		event = log.Warn().Str("reason", reason)
	default:
		event = log.Info()
	}

	event = event.
		Str("method", r.Method).
		Str("route", route).
		Int("status", status).
		Dur("duration", duration)
	if info.Username != "" {
		event = event.Str("user", info.Username)
	}

	if status >= 400 {
		event.Msg("Request failed")
	} else {
		event.Msg("Request answered")
	}
}

// responseWriter is a wrapper around http.ResponseWriter to capture the status code
type responseWriter struct {
	http.ResponseWriter
	statusCode  int
	wroteHeader bool // Prevent multiple calls to WriteHeader
}

// WriteHeader captures the status code and ensures it's only called once
func (rw *responseWriter) WriteHeader(code int) {
	if rw.wroteHeader {
		return // Prevent superfluous calls
	}
	rw.wroteHeader = true
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}

// Write ensures the header is written before writing the body
func (rw *responseWriter) Write(b []byte) (int, error) {
	if !rw.wroteHeader {
		rw.WriteHeader(http.StatusOK) // Default to 200 if WriteHeader wasn't called
	}
	return rw.ResponseWriter.Write(b)
}

// Unwrap lets http.ResponseController reach the original writer.
func (rw *responseWriter) Unwrap() http.ResponseWriter {
	return rw.ResponseWriter
}
