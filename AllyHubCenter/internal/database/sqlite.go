package database

import (
	"database/sql"
	"fmt"
	"time"

	"allyhubcenter/internal/models"

	_ "github.com/mattn/go-sqlite3"
)

type SQLiteDatabase struct {
	db *sql.DB
}

// NewSQLiteDatabase creates a new SQLite database connection
func NewSQLiteDatabase(dbPath string) (*SQLiteDatabase, error) {
	db, err := sql.Open("sqlite3", dbPath)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %v", err)
	}

	// Test connection
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %v", err)
	}

	sqliteDB := &SQLiteDatabase{db: db}

	// Create tables
	if err := sqliteDB.createTables(); err != nil {
		db.Close()
		return nil, fmt.Errorf("failed to create tables: %v", err)
	}

	// Run migrations
	if err := sqliteDB.runMigrations(); err != nil {
		db.Close()
		return nil, fmt.Errorf("failed to run migrations: %v", err)
	}

	return sqliteDB, nil
}

func (db *SQLiteDatabase) createTables() error {
	// Users table
	if _, err := db.db.Exec(`
		CREATE TABLE IF NOT EXISTS users (
			id TEXT PRIMARY KEY,
			email TEXT UNIQUE NOT NULL,
			password TEXT NOT NULL,
			created DATETIME NOT NULL,
			updated DATETIME NOT NULL
		)
	`); err != nil {
		return err
	}

	// Endpoint pools table
	if _, err := db.db.Exec(`
		CREATE TABLE IF NOT EXISTS endpoint_pools (
			id TEXT NOT NULL,
			user_id TEXT NOT NULL,
			name TEXT NOT NULL,
			description TEXT,
			type TEXT NOT NULL DEFAULT 'AllyHub Desktop App',
			endpoints TEXT NOT NULL,
			created DATETIME NOT NULL,
			updated DATETIME NOT NULL,
			is_default BOOLEAN NOT NULL DEFAULT 0,
			PRIMARY KEY (user_id, id),
			FOREIGN KEY (user_id) REFERENCES users(id)
		)
	`); err != nil {
		return err
	}

	// API tokens table
	if _, err := db.db.Exec(`
		CREATE TABLE IF NOT EXISTS api_tokens (
			id TEXT PRIMARY KEY,
			user_id TEXT NOT NULL,
			pool_id TEXT NOT NULL,
			token TEXT NOT NULL,
			name TEXT NOT NULL,
			created DATETIME NOT NULL,
			last_used DATETIME,
			active BOOLEAN NOT NULL DEFAULT 1,
			FOREIGN KEY (user_id) REFERENCES users(id)
		)
	`); err != nil {
		return err
	}

	// Sessions table
	if _, err := db.db.Exec(`
		CREATE TABLE IF NOT EXISTS sessions (
			id TEXT PRIMARY KEY,
			user_id TEXT NOT NULL,
			created DATETIME NOT NULL,
			expires DATETIME NOT NULL,
			FOREIGN KEY (user_id) REFERENCES users(id)
		)
	`); err != nil {
		return err
	}

	return nil
}

// Close closes the database connection
func (db *SQLiteDatabase) Close() error {
	return db.db.Close()
}

// User operations
func (db *SQLiteDatabase) CreateUser(user *models.User) error {
	_, err := db.db.Exec(`
		INSERT INTO users (id, email, password, created, updated)
		VALUES (?, ?, ?, ?, ?)
	`, user.ID, user.Email, user.Password, user.Created, user.Updated)
	return err
}

func (db *SQLiteDatabase) GetUser(id string) (*models.User, error) {
	var user models.User
	err := db.db.QueryRow(`
		SELECT id, email, password, created, updated
		FROM users WHERE id = ?
	`, id).Scan(&user.ID, &user.Email, &user.Password, &user.Created, &user.Updated)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("user not found")
		}
		return nil, err
	}
	return &user, nil
}

func (db *SQLiteDatabase) GetUserByUsername(email string) (*models.User, error) {
	fmt.Printf("GetUserByUsername: looking for email '%s'\n", email)
	var user models.User
	err := db.db.QueryRow(`
		SELECT id, email, password, created, updated
		FROM users WHERE email = ?
	`, email).Scan(&user.ID, &user.Email, &user.Password, &user.Created, &user.Updated)

	if err != nil {
		fmt.Printf("GetUserByUsername: scan error: %v\n", err)
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("user not found")
		}
		return nil, err
	}
	fmt.Printf("GetUserByUsername: found user ID: %s, Email: %s\n", user.ID, user.Email)
	return &user, nil
}

func (db *SQLiteDatabase) UpdateUser(user *models.User) error {
	user.Updated = time.Now()
	_, err := db.db.Exec(`
		UPDATE users SET email = ?, password = ?, updated = ?
		WHERE id = ?
	`, user.Email, user.Password, user.Updated, user.ID)
	return err
}

// EndpointPool operations
func (db *SQLiteDatabase) CreateEndpointPool(pool *models.EndpointPool) error {
	endpointsJSON := ""
	if pool.Endpoints != nil {
		if jsonData, err := models.ToJSONBytes(pool.Endpoints); err == nil {
			endpointsJSON = string(jsonData)
		}
	}

	_, err := db.db.Exec(`
		INSERT INTO endpoint_pools (id, user_id, name, description, type, endpoints, created, updated, is_default)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
	`, pool.ID, pool.UserID, pool.Name, pool.Description, pool.Type, endpointsJSON, pool.Created, pool.Updated, pool.IsDefault)
	return err
}

func (db *SQLiteDatabase) GetEndpointPool(userID, poolID string) (*models.EndpointPool, error) {
	var pool models.EndpointPool
	var endpointsJSON string
	err := db.db.QueryRow(`
		SELECT id, user_id, name, description, type, endpoints, created, updated, is_default
		FROM endpoint_pools WHERE user_id = ? AND id = ?
	`, userID, poolID).Scan(&pool.ID, &pool.UserID, &pool.Name, &pool.Description, &pool.Type, &endpointsJSON, &pool.Created, &pool.Updated, &pool.IsDefault)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("endpoint pool not found")
		}
		return nil, err
	}

	// Parse endpoints JSON
	var endpoints map[string]models.EndpointURL
	if endpointsJSON != "" {
		if err := models.FromJSONBytes([]byte(endpointsJSON), &endpoints); err != nil {
			endpoints = make(map[string]models.EndpointURL)
		}
	} else {
		endpoints = make(map[string]models.EndpointURL)
	}

	pool.Endpoints = endpoints
	return &pool, nil
}

func (db *SQLiteDatabase) GetUserEndpointPools(userID string) ([]*models.EndpointPool, error) {
	rows, err := db.db.Query(`
		SELECT id, user_id, name, description, type, endpoints, created, updated, is_default
		FROM endpoint_pools WHERE user_id = ?
		ORDER BY is_default DESC, created ASC
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var pools []*models.EndpointPool
	for rows.Next() {
		var pool models.EndpointPool
		var endpointsJSON string

		err := rows.Scan(&pool.ID, &pool.UserID, &pool.Name, &pool.Description, &pool.Type, &endpointsJSON, &pool.Created, &pool.Updated, &pool.IsDefault)
		if err != nil {
			continue
		}

		// Parse endpoints JSON
		var endpoints map[string]models.EndpointURL
		if endpointsJSON != "" {
			if err := models.FromJSONBytes([]byte(endpointsJSON), &endpoints); err != nil {
				endpoints = make(map[string]models.EndpointURL)
			}
		} else {
			endpoints = make(map[string]models.EndpointURL)
		}

		pool.Endpoints = endpoints
		pools = append(pools, &pool)
	}

	return pools, nil
}

func (db *SQLiteDatabase) UpdateEndpointPool(pool *models.EndpointPool) error {
	pool.Updated = time.Now()
	return db.CreateEndpointPool(pool) // Simple implementation
}

func (db *SQLiteDatabase) DeleteEndpointPool(userID, poolID string) error {
	_, err := db.db.Exec(`
		DELETE FROM endpoint_pools WHERE user_id = ? AND id = ?
	`, userID, poolID)
	return err
}

// APIToken operations
func (db *SQLiteDatabase) CreateAPIToken(token *models.APIToken) error {
	_, err := db.db.Exec(`
		INSERT INTO api_tokens (id, user_id, pool_id, token, name, created, last_used, active)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)
	`, token.ID, token.UserID, token.PoolID, token.Token, token.Name, token.Created, token.LastUsed, token.Active)
	return err
}

func (db *SQLiteDatabase) GetAPIToken(id string) (*models.APIToken, error) {
	return nil, fmt.Errorf("not implemented")
}

func (db *SQLiteDatabase) GetUserAPITokens(userID string) ([]*models.APIToken, error) {
	rows, err := db.db.Query(`
		SELECT id, user_id, pool_id, token, name, created, last_used, active
		FROM api_tokens WHERE user_id = ?
		ORDER BY created DESC
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tokens []*models.APIToken
	for rows.Next() {
		var token models.APIToken
		var lastUsed sql.NullTime

		err := rows.Scan(&token.ID, &token.UserID, &token.PoolID, &token.Token, &token.Name, &token.Created, &lastUsed, &token.Active)
		if err != nil {
			continue
		}

		if lastUsed.Valid {
			token.LastUsed = lastUsed.Time
		}

		tokens = append(tokens, &token)
	}

	return tokens, nil
}

func (db *SQLiteDatabase) UpdateAPIToken(token *models.APIToken) error {
	return fmt.Errorf("not implemented")
}

func (db *SQLiteDatabase) DeleteAPIToken(id string) error {
	_, err := db.db.Exec(`DELETE FROM api_tokens WHERE id = ?`, id)
	return err
}

// Session operations
func (db *SQLiteDatabase) CreateSession(session *models.Session) error {
	_, err := db.db.Exec(`
		INSERT INTO sessions (id, user_id, created, expires)
		VALUES (?, ?, ?, ?)
	`, session.ID, session.UserID, session.Created, session.Expires)
	return err
}

func (db *SQLiteDatabase) GetSession(id string) (*models.Session, error) {
	var session models.Session
	err := db.db.QueryRow(`
		SELECT id, user_id, created, expires
		FROM sessions WHERE id = ?
	`, id).Scan(&session.ID, &session.UserID, &session.Created, &session.Expires)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("session not found")
		}
		return nil, err
	}
	return &session, nil
}

func (db *SQLiteDatabase) DeleteSession(id string) error {
	_, err := db.db.Exec(`DELETE FROM sessions WHERE id = ?`, id)
	return err
}

// Utility functions
func GenerateID() string {
	return fmt.Sprintf("%d", time.Now().UnixNano())
}

func GenerateToken() string {
	return fmt.Sprintf("token_%d", time.Now().UnixNano())
}

// runMigrations applies schema updates to existing database
func (db *SQLiteDatabase) runMigrations() error {
	// Add type column to endpoint_pools if it doesn't exist
	_, err := db.db.Exec(`ALTER TABLE endpoint_pools ADD COLUMN type TEXT DEFAULT 'AllyHub Desktop App'`)
	if err != nil && !isColumnExistsError(err) {
		return fmt.Errorf("failed to add type column to endpoint_pools: %v", err)
	}

	// Add pool_id column to api_tokens if it doesn't exist
	_, err = db.db.Exec(`ALTER TABLE api_tokens ADD COLUMN pool_id TEXT`)
	if err != nil && !isColumnExistsError(err) {
		return fmt.Errorf("failed to add pool_id column to api_tokens: %v", err)
	}

	return nil
}

// isColumnExistsError checks if the error is due to column already existing
func isColumnExistsError(err error) bool {
	return err != nil && (
		err.Error() == "duplicate column name: type" ||
		err.Error() == "duplicate column name: pool_id")
}