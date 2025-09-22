package main

import (
	"log"
	"os"

	"allyhubcenter/internal/config"
	"allyhubcenter/internal/database"
	"allyhubcenter/internal/handlers"
	"allyhubcenter/internal/middleware"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/gofiber/template/html/v2"
)

func main() {
	// Load pool configuration from YAML
	if err := config.LoadPoolConfig(""); err != nil {
		log.Printf("Warning: Failed to load pool config: %v. Using fallback configuration.", err)
	}

	// Initialize SQLite database
	dbPath := "allyhub.db"
	if env := os.Getenv("DB_PATH"); env != "" {
		dbPath = env
	}

	db, err := database.NewSQLiteDatabase(dbPath)
	if err != nil {
		log.Fatal("Failed to initialize database:", err)
	}
	defer db.Close()

	// Initialize template engine
	engine := html.New("./templates", ".html")
	engine.Reload(true) // Enable auto-reload in development

	// Initialize Fiber app
	app := fiber.New(fiber.Config{
		Views: engine,
		ErrorHandler: func(c *fiber.Ctx, err error) error {
			code := fiber.StatusInternalServerError
			if e, ok := err.(*fiber.Error); ok {
				code = e.Code
			}
			return c.Status(code).JSON(fiber.Map{
				"success": false,
				"message": err.Error(),
			})
		},
	})

	// Global middleware
	app.Use(recover.New())
	app.Use(logger.New())
	app.Use(cors.New(cors.Config{
		AllowOrigins: "*",
		AllowMethods: "GET,POST,PUT,DELETE,OPTIONS",
		AllowHeaders: "Origin,Content-Type,Accept,Authorization",
	}))

	// Static files
	app.Static("/static", "./static")

	// Initialize handlers
	authHandler := handlers.NewAuthHandler(db)
	endpointsHandler := handlers.NewEndpointsHandler(db)

	// Public routes
	app.Get("/", handleHome)
	app.Get("/login", handleLoginPage)
	app.Get("/register", handleRegisterPage)

	// Auth routes
	app.Post("/api/auth/register", authHandler.HandleRegister)
	app.Post("/api/auth/login", authHandler.HandleLogin)
	app.Post("/api/auth/logout", authHandler.HandleLogout)

	// Protected web routes
	web := app.Group("/dashboard", middleware.AuthMiddleware(db))
	web.Get("/", handleDashboard)
	web.Get("/endpoints", handleEndpoints)
	web.Get("/endpoints/:id", handleEndpointDetail)
	web.Get("/tokens", handleTokens)

	// Protected API routes
	api := app.Group("/api", middleware.AuthMiddleware(db))

	// Endpoint pools API
	api.Get("/endpoints", endpointsHandler.HandleGetEndpointPools)
	api.Get("/endpoints/:id", endpointsHandler.HandleGetEndpointPool)
	api.Post("/endpoints", endpointsHandler.HandleCreateEndpointPool)
	api.Put("/endpoints/:id", endpointsHandler.HandleUpdateEndpointPool)
	api.Delete("/endpoints/:id", endpointsHandler.HandleDeleteEndpointPool)

	// AllyHub integration endpoint
	api.Get("/endpoints/:id/allyhub", endpointsHandler.HandleGetAllyHubEndpoints)

	// Get predefined endpoints and pool types
	api.Get("/endpoints-predefined", endpointsHandler.HandleGetPredefinedEndpoints)
	api.Get("/pool-types", endpointsHandler.HandleGetPoolTypes)

	// API tokens API
	api.Get("/tokens", endpointsHandler.HandleGetAPITokens)
	api.Post("/tokens", endpointsHandler.HandleCreateAPIToken)
	api.Delete("/tokens/:id", endpointsHandler.HandleDeleteAPIToken)

	// Health check
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status": "ok",
			"service": "allyhub-center",
		})
	})

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "3030"
	}

	log.Printf("Starting AllyHub Center on port %s", port)
	log.Fatal(app.Listen(":" + port))
}

// Web page handlers
func handleHome(c *fiber.Ctx) error {
	return c.Render("index", fiber.Map{
		"Title": "AllyHub Center",
	})
}

func handleLoginPage(c *fiber.Ctx) error {
	return c.Render("login", fiber.Map{
		"Title": "Login - AllyHub Center",
	})
}

func handleRegisterPage(c *fiber.Ctx) error {
	return c.Render("register", fiber.Map{
		"Title": "Register - AllyHub Center",
	})
}

func handleDashboard(c *fiber.Ctx) error {
	user := c.Locals("user")
	return c.Render("dashboard", fiber.Map{
		"Title": "Dashboard - AllyHub Center",
		"User":  user,
	})
}

func handleEndpoints(c *fiber.Ctx) error {
	user := c.Locals("user")
	return c.Render("endpoints", fiber.Map{
		"Title": "Endpoint Pools - AllyHub Center",
		"User":  user,
	})
}

func handleEndpointDetail(c *fiber.Ctx) error {
	user := c.Locals("user")
	poolID := c.Params("id")
	return c.Render("endpoint_detail", fiber.Map{
		"Title":  "Endpoint Pool - AllyHub Center",
		"User":   user,
		"PoolID": poolID,
	})
}

func handleTokens(c *fiber.Ctx) error {
	user := c.Locals("user")
	return c.Render("tokens", fiber.Map{
		"Title": "API Tokens - AllyHub Center",
		"User":  user,
	})
}