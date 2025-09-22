package database

import "allyhubcenter/internal/models"

// Database interface to make different implementations compatible
type Database interface {
	Close() error
	CreateUser(user *models.User) error
	GetUser(id string) (*models.User, error)
	GetUserByUsername(username string) (*models.User, error)
	UpdateUser(user *models.User) error
	CreateEndpointPool(pool *models.EndpointPool) error
	GetEndpointPool(userID, poolID string) (*models.EndpointPool, error)
	GetUserEndpointPools(userID string) ([]*models.EndpointPool, error)
	UpdateEndpointPool(pool *models.EndpointPool) error
	DeleteEndpointPool(userID, poolID string) error
	CreateAPIToken(token *models.APIToken) error
	GetAPIToken(id string) (*models.APIToken, error)
	GetUserAPITokens(userID string) ([]*models.APIToken, error)
	UpdateAPIToken(token *models.APIToken) error
	DeleteAPIToken(id string) error
	CreateSession(session *models.Session) error
	GetSession(id string) (*models.Session, error)
	DeleteSession(id string) error
}