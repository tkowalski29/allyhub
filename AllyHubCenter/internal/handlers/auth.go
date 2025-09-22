package handlers

import (
	"time"

	"allyhubcenter/internal/auth"
	"allyhubcenter/internal/database"
	"allyhubcenter/internal/models"

	"github.com/gofiber/fiber/v2"
)

type AuthHandler struct {
	db database.Database
}

func NewAuthHandler(db database.Database) *AuthHandler {
	return &AuthHandler{
		db: db,
	}
}

type RegisterRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type APIResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

// HandleRegister handles user registration
func (h *AuthHandler) HandleRegister(c *fiber.Ctx) error {
	var req RegisterRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(APIResponse{
			Success: false,
			Message: "Invalid request body",
		})
	}

	// Validate input
	if req.Email == "" || req.Password == "" {
		return c.Status(fiber.StatusBadRequest).JSON(APIResponse{
			Success: false,
			Message: "Email and password are required",
		})
	}

	// Check if user already exists
	if _, err := h.db.GetUserByUsername(req.Email); err == nil {
		return c.Status(fiber.StatusConflict).JSON(APIResponse{
			Success: false,
			Message: "Email already exists",
		})
	}

	// Hash password
	hashedPassword, err := auth.HashPassword(req.Password)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(APIResponse{
			Success: false,
			Message: "Failed to process password",
		})
	}

	// Create user
	user := &models.User{
		ID:       database.GenerateID(),
		Email:    req.Email,
		Password: hashedPassword,
		Created:  time.Now(),
		Updated:  time.Now(),
	}

	if err := h.db.CreateUser(user); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(APIResponse{
			Success: false,
			Message: "Failed to create user",
		})
	}


	return c.JSON(APIResponse{
		Success: true,
		Message: "User registered successfully",
		Data: fiber.Map{
			"user_id": user.ID,
		},
	})
}

// HandleLogin handles user login
func (h *AuthHandler) HandleLogin(c *fiber.Ctx) error {
	var req LoginRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(APIResponse{
			Success: false,
			Message: "Invalid request body",
		})
	}

	// Get user
	user, err := h.db.GetUserByUsername(req.Email)
	if err != nil {
		println("Login error: failed to get user by email:", req.Email, "error:", err.Error())
		return c.Status(fiber.StatusUnauthorized).JSON(APIResponse{
			Success: false,
			Message: "Invalid email or password",
		})
	}

	// Check password
	if !auth.CheckPasswordHash(req.Password, user.Password) {
		return c.Status(fiber.StatusUnauthorized).JSON(APIResponse{
			Success: false,
			Message: "Invalid email or password",
		})
	}

	// Create session
	session := auth.CreateSession(user.ID)
	if err := h.db.CreateSession(session); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(APIResponse{
			Success: false,
			Message: "Failed to create session",
		})
	}

	// Set session cookie
	c.Cookie(&fiber.Cookie{
		Name:     "session_id",
		Value:    session.ID,
		Expires:  session.Expires,
		HTTPOnly: true,
		Secure:   false, // Set to true in production with HTTPS
		SameSite: "Lax",
	})

	return c.JSON(APIResponse{
		Success: true,
		Message: "Login successful",
		Data: fiber.Map{
			"user_id": user.ID,
		},
	})
}

// HandleLogout handles user logout
func (h *AuthHandler) HandleLogout(c *fiber.Ctx) error {
	sessionID := c.Cookies("session_id")
	if sessionID != "" {
		h.db.DeleteSession(sessionID)
	}

	// Clear session cookie
	c.Cookie(&fiber.Cookie{
		Name:     "session_id",
		Value:    "",
		Expires:  time.Unix(0, 0),
		HTTPOnly: true,
	})

	return c.JSON(APIResponse{
		Success: true,
		Message: "Logout successful",
	})
}