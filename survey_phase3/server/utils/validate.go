package utils

import (
	"errors"
	"fmt"
	"reflect"
	"regexp"
	"strings"

	"github.com/go-playground/validator/v10"
)

// Usernames are pseudonyms like P01, never real names.
var usernamePattern = regexp.MustCompile(`^[A-Za-z0-9_-]{2,32}$`)

// NewValidator returns a validator that reports fields by their JSON name
// (camelCase, as the client sends them) and knows the custom rules:
//   - username: 2 to 32 letters, digits, '_' or '-'.
func NewValidator() *validator.Validate {
	validate := validator.New(validator.WithRequiredStructEnabled())

	validate.RegisterTagNameFunc(func(field reflect.StructField) string {
		name, _, _ := strings.Cut(field.Tag.Get("json"), ",")
		if name == "-" || name == "" {
			return field.Name
		}
		return name
	})

	validate.RegisterValidation("username", func(fl validator.FieldLevel) bool {
		return usernamePattern.MatchString(fl.Field().String())
	})

	return validate
}

// Given an struct tagged with Go Validator tags, it validates it.
// If success:
//   - Returns nil, nil
//
// If a validation rule is broken it returns :
//   - A map with an entry for each rule broken, nil
func ValidateStruct(validate *validator.Validate, target any) (map[string]string, error) {
	// Validate the struct
	if err := validate.Struct(target); err != nil {
		var validationErrors validator.ValidationErrors
		if !errors.As(err, &validationErrors) {
			return nil, err
		}
		errorDetails := make(map[string]string)

		// Map validation errors
		for _, vErr := range validationErrors {
			// Construct a human-readable error message
			errorDetails[vErr.Field()] = formatValidationError(vErr)
		}

		return errorDetails, errors.New("validation failed")
	}

	// No validation errors
	return nil, nil
}

// Helper function to format a validation error
func formatValidationError(vErr validator.FieldError) string {
	switch vErr.Tag() {
	case "required":
		return "is required"
	case "max":
		return fmt.Sprintf("must be at most %s", vErr.Param())
	case "min":
		return fmt.Sprintf("must be at least %s", vErr.Param())
	case "email":
		return "must be a valid email address"
	case "email_domain":
		return "must be a valid email domain extension (e.g., @example.com)"
	case "oneof":
		return fmt.Sprintf("must be one of: %s", vErr.Param())
	case "len":
		return fmt.Sprintf("must be exactly %s characters long", vErr.Param())
	case "uuid":
		return "must be a valid UUID"
	case "username":
		return "must be 2 to 32 letters, digits, '_' or '-'"
	default:
		return fmt.Sprintf("failed validation on rule '%s'", vErr.Tag())
	}
}
