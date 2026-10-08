package users_s

import (
	"strings"
	"testing"
)

func TestGeneratePassword(t *testing.T) {
	seen := map[string]bool{}
	for range 200 {
		password, err := GeneratePassword()
		if err != nil {
			t.Fatal(err)
		}
		if len(password) != passwordLength {
			t.Fatalf("password %q has %d characters, want %d", password, len(password), passwordLength)
		}
		if strings.ContainsAny(password, "0O1lI") {
			t.Fatalf("password %q has an ambiguous character", password)
		}
		for _, c := range password {
			if !strings.ContainsRune(passwordAlphabet, c) {
				t.Fatalf("password %q has %q, not in the alphabet", password, c)
			}
		}
		if seen[password] {
			t.Fatalf("password %q generated twice", password)
		}
		seen[password] = true
	}
}
