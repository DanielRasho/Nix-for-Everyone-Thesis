package config

import (
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/rs/zerolog/log"
)

type LoggingConfig struct {
	LoggingLevel string
	PrettyLogs   string
}

type CorsConfig struct {
	AllowedOrigins      []string
	AllowedContentTypes []string
	AllowedMethods      []string
	AllowedHeaders      []string
}

// AdminConfig is the admin account, created or updated at every startup.
type AdminConfig struct {
	Username string
	Password string
}

type SessionConfig struct {
	CookieSecure bool          // send the cookie only over HTTPS (true in production)
	TTL          time.Duration // how long a login lasts
}

func LoadRunningModeConfig() string {
	return mustGetEnv("API_PORT")
}

func LoadDBConfig() string {
	return mustGetEnv("DB_URI")
}

func LoadLoggingConfig() LoggingConfig {
	return LoggingConfig{
		LoggingLevel: mustGetEnv("LOGGING_LEVEL"),
		PrettyLogs:   mustGetEnv("LOGGING_PRETTY"),
	}
}

func LoadCorsConfig() CorsConfig {
	return CorsConfig{
		AllowedOrigins:      mustGetEnvAsStringSlice("ALLOWED_ORIGINS"),
		AllowedContentTypes: mustGetEnvAsStringSlice("ALLOWED_CONTENT_TYPES"),
		AllowedMethods:      mustGetEnvAsStringSlice("ALLOWED_METHODS"),
		AllowedHeaders:      mustGetEnvAsStringSlice("ALLOWED_HEADERS"),
	}
}

func LoadAdminConfig() AdminConfig {
	config := AdminConfig{
		Username: mustGetEnv("ADMIN_USERNAME"),
		Password: mustGetEnv("ADMIN_PASSWORD"),
	}
	if config.Username == "" || config.Password == "" {
		log.Fatal().Msg("Environment variables ADMIN_USERNAME and ADMIN_PASSWORD cannot be empty")
	}
	return config
}

func LoadSessionConfig() SessionConfig {
	secure, err := strconv.ParseBool(getEnvOrDefault("COOKIE_SECURE", "false"))
	if err != nil {
		log.Fatal().Msgf("Environment variable COOKIE_SECURE must be a boolean: %v", err)
	}

	ttlHours, err := strconv.Atoi(getEnvOrDefault("SESSION_TTL_HOURS", "168"))
	if err != nil || ttlHours <= 0 {
		log.Fatal().Msgf("Environment variable SESSION_TTL_HOURS must be a positive integer")
	}

	return SessionConfig{
		CookieSecure: secure,
		TTL:          time.Duration(ttlHours) * time.Hour,
	}
}

// mustGetEnv retrieves the value of the given environment variable
// or exits with a fatal error if the variable is not set.
func mustGetEnv(key string) string {
	value, exists := os.LookupEnv(key)
	if !exists {
		log.Fatal().Msgf("Environment variable %s is required but not set", key)
	}
	return value
}

// mustGetEnvAsInt retrieves the value of the given environment variable,
// converts it to an integer, or exits with a fatal error if the variable
// is not set or cannot be converted to an integer.
func mustGetEnvAsInt(key string) int {
	valueStr := mustGetEnv(key)
	value, err := strconv.Atoi(valueStr)
	if err != nil {
		log.Fatal().Msgf("Environment variable %s must be a valid integer: %v", key, err)
	}
	return value
}

func mustGetEnvAsStringSlice(key string) []string {
	value, exists := os.LookupEnv(key)
	if !exists {
		log.Fatal().Msgf("Environment variable %s is required but not set", key)
	}

	return strings.Split(value, ",")
}

func mustGetEnvAsEnum(key string, enumValues []string) string {
	value := mustGetEnv(key)
	for _, enumValue := range enumValues {
		if value == enumValue {
			return value
		}
	}
	log.Fatal().Msgf("Environment variable %s must be one of %v", key, enumValues)
	return ""
}

func getEnvOrDefault(key, def string) string {
	value, exist := os.LookupEnv(key)
	if !exist {
		return def
	}
	return value
}
