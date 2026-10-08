package utils

import (
	"fmt"
	"net/http"
)

// VerificationError is an expected failure of a request (bad input, missing
// resource, wrong state...). It answers Code's status and message, plus the
// per-field errors in UserError, while Err is the detailed reason that only
// goes to the logs.
type VerificationError struct {
	Err       error
	Code      *DefaultMsg
	UserError map[string]string
}

func (e *VerificationError) Error() string {
	return e.Err.Error()
}

// Reject builds a VerificationError answered with code, the formatted reason
// is logged but never sent to the client.
func Reject(code *DefaultMsg, format string, args ...any) *VerificationError {
	return &VerificationError{Err: fmt.Errorf(format, args...), Code: code}
}

// RejectFields builds a VerificationError that also tells the client which
// field broke which rule: { "message": ..., "errors": { field: reason } }.
func RejectFields(code *DefaultMsg, fields map[string]string) *VerificationError {
	return &VerificationError{Err: fmt.Errorf("%s", formatFields(fields)), Code: code, UserError: fields}
}

// This file provides Constant definition to API RESPONSES

// Structure of API Messages responses
type DefaultMsg struct {
	Message    string
	StatusCode int
}

func (e *DefaultMsg) Error() string {
	return e.Message
}

// List of Common Response messages for different kinf of errors.
// IS PREFERABLE that ALL common response messages reside here.
var (
	// 200: Success
	RequestSuccess = &DefaultMsg{"Request successful.", http.StatusOK}

	// 400: Missing data on request
	BadRequest      = &DefaultMsg{"Bad request", http.StatusBadRequest}
	WrongFieldsType = &DefaultMsg{"Fields of wrong type", http.StatusBadRequest}
	FailedToDecode  = &DefaultMsg{"Failed to decode request", http.StatusBadRequest}
	FailedToEncode  = &DefaultMsg{"Failed to encode request", http.StatusBadRequest}
	InvalidFields   = &DefaultMsg{"Request contains invalid fields.", http.StatusBadRequest}
	InvalidID       = &DefaultMsg{"Invalid id", http.StatusBadRequest}
	NotGradable     = &DefaultMsg{"Only free_code answers can be graded", http.StatusBadRequest}

	// 401: No valid session
	Unauthorized     = &DefaultMsg{"You must log in", http.StatusUnauthorized}
	WrongCredentials = &DefaultMsg{"Wrong username or password", http.StatusUnauthorized}

	// 403: Logged in, but not allowed
	Forbidden  = &DefaultMsg{"Forbidden", http.StatusForbidden}
	StepLocked = &DefaultMsg{"This step is locked until the previous ones are completed", http.StatusForbidden}

	// 404: Resource not found
	NotFound            = &DefaultMsg{"Not found", http.StatusNotFound}
	ResourceNotFound    = &DefaultMsg{"Resource not found for given parameters", http.StatusNotFound}
	StepNotFound        = &DefaultMsg{"Step not found", http.StatusNotFound}
	QuestionNotFound    = &DefaultMsg{"Question not found", http.StatusNotFound}
	ParticipantNotFound = &DefaultMsg{"Participant not found", http.StatusNotFound}
	AnswerNotFound      = &DefaultMsg{"Answer not found", http.StatusNotFound}

	// 405: Route exists, but not with this method
	MethodNotAllowed = &DefaultMsg{"Method not allowed", http.StatusMethodNotAllowed}

	// 409: Conflict with the current state
	UsernameExists     = &DefaultMsg{"Username already exists", http.StatusConflict}
	NotCurrentQuestion = &DefaultMsg{"The question is not the current one", http.StatusConflict}

	// 500: Internal Server Error
	BadDatabaseOperation = &DefaultMsg{"Failed to execute DB operations.", http.StatusInternalServerError}
	InternalServerError  = &DefaultMsg{"Internal server error", http.StatusInternalServerError}
)
