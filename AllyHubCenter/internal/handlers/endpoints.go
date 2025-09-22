package handlers

import (
	"time"

	"allyhubcenter/internal/config"
	"allyhubcenter/internal/database"
	"allyhubcenter/internal/models"

	"github.com/gofiber/fiber/v2"
)

type EndpointsHandler struct {
	db database.Database
}

func NewEndpointsHandler(db database.Database) *EndpointsHandler {
	return &EndpointsHandler{db: db}
}

type CreateEndpointPoolRequest struct {
	Name        string                           `json:"name"`
	Description string                           `json:"description"`
	Type        string                           `json:"type"`
	Endpoints   map[string]models.EndpointURL    `json:"endpoints"`
}

type UpdateEndpointPoolRequest struct {
	Name        string                           `json:"name"`
	Description string                           `json:"description"`
	Endpoints   map[string]models.EndpointURL    `json:"endpoints"`
}

// HandleGetEndpointPools returns all endpoint pools for the authenticated user
func (h *EndpointsHandler) HandleGetEndpointPools(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)

	pools, err := h.db.GetUserEndpointPools(user.ID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(APIResponse{
			Success: false,
			Message: "Failed to get endpoint pools",
		})
	}

	return c.JSON(APIResponse{
		Success: true,
		Message: "Endpoint pools retrieved successfully",
		Data:    pools,
	})
}

// HandleGetEndpointPool returns a specific endpoint pool
func (h *EndpointsHandler) HandleGetEndpointPool(c *fiber.Ctx) error {
	poolID := c.Params("id")
	user := c.Locals("user").(*models.User)

	pool, err := h.db.GetEndpointPool(user.ID, poolID)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(APIResponse{
			Success: false,
			Message: "Endpoint pool not found",
		})
	}

	return c.JSON(APIResponse{
		Success: true,
		Message: "Endpoint pool retrieved successfully",
		Data:    pool,
	})
}

// HandleCreateEndpointPool creates a new endpoint pool
func (h *EndpointsHandler) HandleCreateEndpointPool(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)

	var req CreateEndpointPoolRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(APIResponse{
			Success: false,
			Message: "Invalid request body",
		})
	}

	// Validate input
	if req.Name == "" {
		return c.Status(fiber.StatusBadRequest).JSON(APIResponse{
			Success: false,
			Message: "Name is required",
		})
	}

	// Create endpoint pool
	poolType := req.Type
	if poolType == "" {
		poolType = "AllyHub Desktop App"
	}

	pool := &models.EndpointPool{
		ID:          database.GenerateID(),
		UserID:      user.ID,
		Name:        req.Name,
		Description: req.Description,
		Type:        poolType,
		Endpoints:   models.GetPredefinedEndpoints(poolType),
		Created:     time.Now(),
		Updated:     time.Now(),
		IsDefault:   false,
	}

	if err := h.db.CreateEndpointPool(pool); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(APIResponse{
			Success: false,
			Message: "Failed to create endpoint pool",
		})
	}

	return c.JSON(APIResponse{
		Success: true,
		Message: "Endpoint pool created successfully",
		Data:    pool,
	})
}

// HandleUpdateEndpointPool updates an existing endpoint pool
func (h *EndpointsHandler) HandleUpdateEndpointPool(c *fiber.Ctx) error {
	poolID := c.Params("id")
	user := c.Locals("user").(*models.User)

	// Get existing pool
	pool, err := h.db.GetEndpointPool(user.ID, poolID)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(APIResponse{
			Success: false,
			Message: "Endpoint pool not found",
		})
	}

	var req UpdateEndpointPoolRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(APIResponse{
			Success: false,
			Message: "Invalid request body",
		})
	}

	// Update pool
	pool.Name = req.Name
	pool.Description = req.Description
	pool.Endpoints = req.Endpoints
	pool.Updated = time.Now()

	if err := h.db.UpdateEndpointPool(pool); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(APIResponse{
			Success: false,
			Message: "Failed to update endpoint pool",
		})
	}

	return c.JSON(APIResponse{
		Success: true,
		Message: "Endpoint pool updated successfully",
		Data:    pool,
	})
}

// HandleDeleteEndpointPool deletes an endpoint pool
func (h *EndpointsHandler) HandleDeleteEndpointPool(c *fiber.Ctx) error {
	poolID := c.Params("id")
	user := c.Locals("user").(*models.User)

	// Check if pool exists and belongs to user
	_, err := h.db.GetEndpointPool(user.ID, poolID)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(APIResponse{
			Success: false,
			Message: "Endpoint pool not found",
		})
	}


	if err := h.db.DeleteEndpointPool(user.ID, poolID); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(APIResponse{
			Success: false,
			Message: "Failed to delete endpoint pool",
		})
	}

	return c.JSON(APIResponse{
		Success: true,
		Message: "Endpoint pool deleted successfully",
	})
}

// HandleGetAllyHubEndpoints returns endpoints in AllyHub format
func (h *EndpointsHandler) HandleGetAllyHubEndpoints(c *fiber.Ctx) error {
	poolID := c.Params("id")
	user := c.Locals("user").(*models.User)

	pool, err := h.db.GetEndpointPool(user.ID, poolID)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(APIResponse{
			Success: false,
			Message: "Endpoint pool not found",
		})
	}

	allyHubEndpoints := pool.GetAllyHubEndpoints()
	return c.JSON(APIResponse{
		Success: true,
		Message: "AllyHub endpoints retrieved successfully",
		Data:    allyHubEndpoints,
	})
}

// API Token handlers

type CreateAPITokenRequest struct {
	Name   string `json:"name"`
	PoolID string `json:"pool_id"`
}

// HandleGetAPITokens returns all API tokens for the authenticated user
func (h *EndpointsHandler) HandleGetAPITokens(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)

	tokens, err := h.db.GetUserAPITokens(user.ID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(APIResponse{
			Success: false,
			Message: "Failed to get API tokens",
		})
	}

	return c.JSON(APIResponse{
		Success: true,
		Message: "API tokens retrieved successfully",
		Data:    tokens,
	})
}

// HandleCreateAPIToken creates a new API token
func (h *EndpointsHandler) HandleCreateAPIToken(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)

	var req CreateAPITokenRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(APIResponse{
			Success: false,
			Message: "Invalid request body",
		})
	}

	// Validate input
	if req.Name == "" {
		return c.Status(fiber.StatusBadRequest).JSON(APIResponse{
			Success: false,
			Message: "Name is required",
		})
	}

	if req.PoolID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(APIResponse{
			Success: false,
			Message: "Pool ID is required",
		})
	}

	// Verify pool exists and belongs to user
	_, err := h.db.GetEndpointPool(user.ID, req.PoolID)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(APIResponse{
			Success: false,
			Message: "Invalid pool ID",
		})
	}

	// Create API token
	token := &models.APIToken{
		ID:       database.GenerateID(),
		UserID:   user.ID,
		PoolID:   req.PoolID,
		Token:    database.GenerateToken(),
		Name:     req.Name,
		Created:  time.Now(),
		Active:   true,
	}

	if err := h.db.CreateAPIToken(token); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(APIResponse{
			Success: false,
			Message: "Failed to create API token",
		})
	}

	return c.JSON(APIResponse{
		Success: true,
		Message: "API token created successfully",
		Data:    token,
	})
}

// HandleDeleteAPIToken deletes an API token
func (h *EndpointsHandler) HandleDeleteAPIToken(c *fiber.Ctx) error {
	tokenID := c.Params("id")

	if err := h.db.DeleteAPIToken(tokenID); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(APIResponse{
			Success: false,
			Message: "Failed to delete API token",
		})
	}

	return c.JSON(APIResponse{
		Success: true,
		Message: "API token deleted successfully",
	})
}

// HandleGetPredefinedEndpoints returns predefined endpoints for a pool type
func (h *EndpointsHandler) HandleGetPredefinedEndpoints(c *fiber.Ctx) error {
	poolType := c.Query("type")
	if poolType == "" {
		poolType = "AllyHub Desktop App"
	}

	endpoints := models.GetPredefinedEndpoints(poolType)

	return c.JSON(APIResponse{
		Success: true,
		Message: "Predefined endpoints retrieved successfully",
		Data:    endpoints,
	})
}

// HandleGetPoolTypes returns available pool types from configuration
func (h *EndpointsHandler) HandleGetPoolTypes(c *fiber.Ctx) error {
	poolTypes := config.GetPoolTypes()

	return c.JSON(APIResponse{
		Success: true,
		Message: "Pool types retrieved successfully",
		Data:    poolTypes,
	})
}