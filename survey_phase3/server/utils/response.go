package utils

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"sort"
	"strings"

	"github.com/go-playground/validator/v10"
)

// Bodies bigger than this are rejected (free_code answers are the largest).
const maxBodyBytes = 1 << 20

// ErrorBody is the body of every error response.
type ErrorBody struct {
	Message string            `json:"message"`
	Errors  map[string]string `json:"errors,omitempty"`
}

// WriteJSON answers status with body encoded as JSON.
func WriteJSON(w http.ResponseWriter, r *http.Request, status int, body any) {
	payload, err := json.Marshal(body)
	if err != nil {
		WriteError(w, r, fmt.Errorf("encoding response: %w", err))
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	w.Write(append(payload, '\n'))
}

// WriteError answers an error and records its reason for the request log.
//
//   - *VerificationError: its Code's status and message, plus its field errors.
//   - *DefaultMsg: its status and message.
//   - anything else: 500, the error is logged but never sent to the client.
func WriteError(w http.ResponseWriter, r *http.Request, err error) {
	info := RequestLogFrom(r.Context())

	var vErr *VerificationError
	var msg *DefaultMsg
	switch {
	case errors.As(err, &vErr):
		info.Reason = vErr.Error()
		writeErrorBody(w, vErr.Code.StatusCode, ErrorBody{Message: vErr.Code.Message, Errors: vErr.UserError})
	case errors.As(err, &msg):
		info.Reason = msg.Message
		writeErrorBody(w, msg.StatusCode, ErrorBody{Message: msg.Message})
	default:
		info.Err = err
		writeErrorBody(w, InternalServerError.StatusCode, ErrorBody{Message: InternalServerError.Message})
	}
}

func writeErrorBody(w http.ResponseWriter, status int, body ErrorBody) {
	payload, _ := json.Marshal(body) // a string and a map of strings always encode
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	w.Write(append(payload, '\n'))
}

// DecodeJSON reads the request body into target and validates its struct tags.
// Failures are *VerificationError (400) ready for WriteError.
func DecodeJSON(w http.ResponseWriter, r *http.Request, validate *validator.Validate, target any) error {
	decoder := json.NewDecoder(http.MaxBytesReader(w, r.Body, maxBodyBytes))
	if err := decoder.Decode(target); err != nil {
		var typeErr *json.UnmarshalTypeError
		var sizeErr *http.MaxBytesError
		switch {
		case errors.Is(err, io.EOF):
			return Reject(FailedToDecode, "request body is empty")
		case errors.As(err, &typeErr) && typeErr.Field != "":
			return RejectFields(WrongFieldsType, map[string]string{
				typeErr.Field: "must be of type " + jsonTypeName(typeErr.Type.Kind().String()),
			})
		case errors.As(err, &sizeErr):
			return Reject(BadRequest, "request body is larger than %d bytes", sizeErr.Limit)
		default:
			return Reject(FailedToDecode, "invalid JSON body: %v", err)
		}
	}

	if fields, err := ValidateStruct(validate, target); err != nil {
		return RejectFields(InvalidFields, fields)
	}
	return nil
}

func jsonTypeName(goKind string) string {
	switch {
	case goKind == "string":
		return "string"
	case goKind == "bool":
		return "boolean"
	case strings.HasPrefix(goKind, "int"), strings.HasPrefix(goKind, "uint"), strings.HasPrefix(goKind, "float"):
		return "number"
	case goKind == "slice", goKind == "array":
		return "array"
	default:
		return "object"
	}
}

// formatFields turns field errors into a stable, single line reason for the logs.
func formatFields(fields map[string]string) string {
	names := make([]string, 0, len(fields))
	for name := range fields {
		names = append(names, name)
	}
	sort.Strings(names)

	parts := make([]string, 0, len(names))
	for _, name := range names {
		parts = append(parts, name+" "+fields[name])
	}
	return strings.Join(parts, "; ")
}
