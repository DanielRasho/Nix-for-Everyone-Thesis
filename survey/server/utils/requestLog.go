package utils

import "context"

// RequestLog collects what the logging middleware needs to write the single
// log line of a request. The middleware puts it in the request context and the
// rest of the chain fills it: the session middleware sets the user, and
// WriteError sets why the request failed.
type RequestLog struct {
	Username string
	Reason   string // 4xx: why the request was rejected
	Err      error  // 5xx: the underlying error
}

type requestLogKey struct{}

// WithRequestLog returns a copy of ctx carrying info.
func WithRequestLog(ctx context.Context, info *RequestLog) context.Context {
	return context.WithValue(ctx, requestLogKey{}, info)
}

// RequestLogFrom returns the RequestLog of the request. It never returns nil,
// so callers can always write to it (outside the middleware it is discarded).
func RequestLogFrom(ctx context.Context) *RequestLog {
	if info, ok := ctx.Value(requestLogKey{}).(*RequestLog); ok {
		return info
	}
	return &RequestLog{}
}
