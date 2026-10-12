package utils

import (
	"regexp"

	"github.com/jackc/pgx/v5/pgtype"
)

var uuidPattern = regexp.MustCompile(`^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$`)

// ParseUUID parses a UUID in its canonical form (8-4-4-4-12 hex digits).
func ParseUUID(s string) (pgtype.UUID, bool) {
	var id pgtype.UUID
	if !uuidPattern.MatchString(s) || id.Scan(s) != nil {
		return pgtype.UUID{}, false
	}
	return id, true
}
