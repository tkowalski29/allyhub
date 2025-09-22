package middleware

import (
	"time"

	"allyhubcenter/internal/auth"
	"allyhubcenter/internal/database"

	"github.com/gofiber/fiber/v2"
)

// AuthMiddleware handles session-based authentication for web routes
func AuthMiddleware(db database.Database) fiber.Handler {
	return func(c *fiber.Ctx) error {
		sessionID := c.Cookies("session_id")
		if sessionID == "" {
			return c.Redirect("/login")
		}

		// Get session from database
		session, err := db.GetSession(sessionID)
		if err != nil || !auth.IsSessionValid(session) {
			// Clear invalid session cookie
			c.Cookie(&fiber.Cookie{
				Name:     "session_id",
				Value:    "",
				Expires:  time.Unix(0, 0),
				HTTPOnly: true,
			})
			return c.Redirect("/login")
		}

		// Get user
		user, err := db.GetUser(session.UserID)
		if err != nil {
			return c.Redirect("/login")
		}

		// Add user to context
		c.Locals("user", user)
		return c.Next()
	}
}

// APIAuthMiddleware handles API token-based authentication
func APIAuthMiddleware(db database.Database, requiredScope string) fiber.Handler {
	return func(c *fiber.Ctx) error {
		authHeader := c.Get("Authorization")
		if authHeader == "" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"success": false,
				"message": "Authorization header required",
			})
		}

		// Expected format: "Bearer <token>"
		if len(authHeader) < 7 || authHeader[:7] != "Bearer " {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"success": false,
				"message": "Invalid authorization header format",
			})
		}

		// For the demo, we'll return unauthorized for now
		// This would need proper implementation with token lookup
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"success": false,
			"message": "Token validation not implemented",
		})
	}
}

// CORSMiddleware for API endpoints
func CORSMiddleware() fiber.Handler {
	return func(c *fiber.Ctx) error {
		c.Set("Access-Control-Allow-Origin", "*")
		c.Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Set("Access-Control-Allow-Headers", "Authorization, Content-Type")

		if c.Method() == "OPTIONS" {
			return c.SendStatus(fiber.StatusOK)
		}

		return c.Next()
	}
}

// LoggingMiddleware logs requests
func LoggingMiddleware() fiber.Handler {
	return func(c *fiber.Ctx) error {
		start := time.Now()

		err := c.Next()

		duration := time.Since(start)
		println(c.Method(), c.Path(), c.Response().StatusCode(), duration.String())

		return err
	}
}