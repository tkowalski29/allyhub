package models

import (
	"encoding/json"
	"time"

	"allyhubcenter/internal/config"
)

// User represents a user in the system
type User struct {
	ID       string    `json:"id"`
	Email    string    `json:"email"`
	Password string    `json:"-"` // Never serialize password
	Created  time.Time `json:"created"`
	Updated  time.Time `json:"updated"`
}

// EndpointPool represents a group of endpoints
type EndpointPool struct {
	ID          string                 `json:"id"`
	UserID      string                 `json:"user_id"`
	Name        string                 `json:"name"`
	Description string                 `json:"description"`
	Type        string                 `json:"type"` // e.g., "AllyHub Desktop App"
	Endpoints   map[string]EndpointURL `json:"endpoints"`
	Created     time.Time              `json:"created"`
	Updated     time.Time              `json:"updated"`
	IsDefault   bool                   `json:"is_default"`
}

// EndpointURL represents a single endpoint configuration
type EndpointURL struct {
	URL         string            `json:"url"`
	Method      string            `json:"method"` // GET, POST, etc.
	Headers     map[string]string `json:"headers,omitempty"`
	Description string            `json:"description,omitempty"`
}

// APIToken represents an API token for external access
type APIToken struct {
	ID       string    `json:"id"`
	UserID   string    `json:"user_id"`
	PoolID   string    `json:"pool_id"` // Reference to endpoint pool
	Token    string    `json:"token"`
	Name     string    `json:"name"`
	Created  time.Time `json:"created"`
	LastUsed time.Time `json:"last_used,omitempty"`
	Active   bool      `json:"active"`
}

// Session represents a user session
type Session struct {
	ID      string    `json:"id"`
	UserID  string    `json:"user_id"`
	Created time.Time `json:"created"`
	Expires time.Time `json:"expires"`
}

// AllyHubEndpoints represents the 6 endpoints that AllyHub expects
type AllyHubEndpoints struct {
	TasksFetch          string `json:"tasks_fetch"`
	TasksUpdate         string `json:"tasks_update"`
	ChatHistory         string `json:"chat_history"`
	ChatStream          string `json:"chat_stream"`
	NotificationsFetch  string `json:"notifications_fetch"`
	NotificationsStatus string `json:"notifications_status"`
}

// ToJSON converts a struct to JSON bytes
func (u *User) ToJSON() ([]byte, error) {
	return json.Marshal(u)
}

func (ep *EndpointPool) ToJSON() ([]byte, error) {
	return json.Marshal(ep)
}

func (at *APIToken) ToJSON() ([]byte, error) {
	return json.Marshal(at)
}

func (s *Session) ToJSON() ([]byte, error) {
	return json.Marshal(s)
}

// FromJSON converts JSON bytes to struct
func (u *User) FromJSON(data []byte) error {
	return json.Unmarshal(data, u)
}

func (ep *EndpointPool) FromJSON(data []byte) error {
	return json.Unmarshal(data, ep)
}

func (at *APIToken) FromJSON(data []byte) error {
	return json.Unmarshal(data, at)
}

func (s *Session) FromJSON(data []byte) error {
	return json.Unmarshal(data, s)
}

// Utility JSON functions
func ToJSONBytes(v interface{}) ([]byte, error) {
	return json.Marshal(v)
}

func FromJSONBytes(data []byte, v interface{}) error {
	return json.Unmarshal(data, v)
}

// GetAllyHubEndpoints returns the 6 endpoints in AllyHub format
func (ep *EndpointPool) GetAllyHubEndpoints() AllyHubEndpoints {
	return AllyHubEndpoints{
		TasksFetch:          ep.Endpoints["tasks_fetch"].URL,
		TasksUpdate:         ep.Endpoints["tasks_update"].URL,
		ChatHistory:         ep.Endpoints["chat_history"].URL,
		ChatStream:          ep.Endpoints["chat_stream"].URL,
		NotificationsFetch:  ep.Endpoints["notifications_fetch"].URL,
		NotificationsStatus: ep.Endpoints["notifications_status"].URL,
	}
}

// GetPredefinedEndpoints returns available endpoints based on pool type from YAML config
func GetPredefinedEndpoints(poolType string) map[string]EndpointURL {
	endpointConfigs := config.GetEndpointsForPoolType(poolType)
	endpoints := make(map[string]EndpointURL)

	for _, endpointConfig := range endpointConfigs {
		endpoints[endpointConfig.Name] = EndpointURL{
			URL:         "", // User will set this
			Method:      endpointConfig.Method,
			Description: endpointConfig.Description,
		}
	}

	return endpoints
}

// CreateDefaultEndpointPool creates a default endpoint pool for a user
func CreateDefaultEndpointPool(userID string) *EndpointPool {
	return &EndpointPool{
		ID:          "default",
		UserID:      userID,
		Name:        "Default Endpoints",
		Description: "Default endpoint configuration for AllyHub",
		Type:        "AllyHub Desktop App",
		Endpoints: map[string]EndpointURL{
			"tasks_fetch": {
				URL:         "http://localhost:8080/api/tasks",
				Method:      "GET",
				Description: "Fetch all tasks",
			},
			"tasks_update": {
				URL:         "http://localhost:8080/api/tasks",
				Method:      "POST",
				Description: "Update task status",
			},
			"chat_history": {
				URL:         "http://localhost:8080/api/chat/history",
				Method:      "GET",
				Description: "Get chat conversation history",
			},
			"chat_stream": {
				URL:         "http://localhost:8080/api/chat/stream",
				Method:      "POST",
				Description: "Stream chat messages",
			},
			"notifications_fetch": {
				URL:         "http://localhost:8080/api/notifications",
				Method:      "GET",
				Description: "Fetch notifications",
			},
			"notifications_status": {
				URL:         "http://localhost:8080/api/notifications/status",
				Method:      "POST",
				Description: "Update notification status",
			},
		},
		Created:   time.Now(),
		Updated:   time.Now(),
		IsDefault: true,
	}
}