package users_s

import (
	"crypto/rand"
	"fmt"
	"math/big"
)

const (
	passwordLength = 12
	// Letters and digits that can't be confused when read aloud or copied by
	// hand: no 0/O, no 1/l/I.
	passwordAlphabet = "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789"
)

// GeneratePassword returns a random password for a participant. Every
// character is drawn uniformly from passwordAlphabet with crypto/rand.
func GeneratePassword() (string, error) {
	password := make([]byte, passwordLength)
	max := big.NewInt(int64(len(passwordAlphabet)))
	for i := range password {
		n, err := rand.Int(rand.Reader, max)
		if err != nil {
			return "", fmt.Errorf("generating password: %w", err)
		}
		password[i] = passwordAlphabet[n.Int64()]
	}
	return string(password), nil
}
