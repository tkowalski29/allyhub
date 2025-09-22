package auth

import (
	"crypto/rand"
	"crypto/subtle"
	"encoding/hex"
	"time"

	"allyhubcenter/internal/models"

	"golang.org/x/crypto/bcrypt"
)

// HashPassword hashes a password using bcrypt
func HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return string(bytes), err
}

// CheckPasswordHash verifies a password against its hash
func CheckPasswordHash(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}

// GenerateSessionID generates a secure session ID
func GenerateSessionID() string {
	bytes := make([]byte, 32)
	rand.Read(bytes)
	return hex.EncodeToString(bytes)
}

// GenerateAPIToken generates a secure API token
func GenerateAPIToken() string {
	bytes := make([]byte, 32)
	rand.Read(bytes)
	return hex.EncodeToString(bytes)
}

// CreateSession creates a new session for a user
func CreateSession(userID string) *models.Session {
	return &models.Session{
		ID:      GenerateSessionID(),
		UserID:  userID,
		Created: time.Now(),
		Expires: time.Now().Add(24 * time.Hour), // 24 hour session
	}
}

// CreateAPIToken creates a new API token for a user
func CreateAPIToken(userID, name, poolID string) *models.APIToken {
	return &models.APIToken{
		ID:       GenerateSessionID(),
		UserID:   userID,
		PoolID:   poolID,
		Token:    GenerateAPIToken(),
		Name:     name,
		Created:  time.Now(),
		LastUsed: time.Time{},
		Active:   true,
	}
}

// IsSessionValid checks if a session is still valid
func IsSessionValid(session *models.Session) bool {
	return time.Now().Before(session.Expires)
}

// ValidateAPIToken checks if an API token is valid
func ValidateAPIToken(providedToken string, storedToken *models.APIToken) bool {
	if !storedToken.Active {
		return false
	}

	// Use constant time comparison to prevent timing attacks
	return subtle.ConstantTimeCompare([]byte(providedToken), []byte(storedToken.Token)) == 1
}

// GetPoolID returns the pool ID associated with the token
func GetPoolID(token *models.APIToken) string {
	return token.PoolID
}