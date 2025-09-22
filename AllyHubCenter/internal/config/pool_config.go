package config

import (
	"fmt"
	"io/ioutil"

	"gopkg.in/yaml.v2"
)

type EndpointConfig struct {
	Name        string `yaml:"name"`
	Method      string `yaml:"method"`
	Description string `yaml:"description"`
}

type PoolTypeConfig struct {
	Name      string           `yaml:"name"`
	Endpoints []EndpointConfig `yaml:"endpoints"`
}

type PoolConfiguration struct {
	PoolTypes []PoolTypeConfig `yaml:"pool_types"`
}

var poolConfig *PoolConfiguration

// LoadPoolConfig loads pool configuration from YAML file
func LoadPoolConfig(configPath string) error {
	if configPath == "" {
		configPath = "config/pool_types.yaml"
	}

	data, err := ioutil.ReadFile(configPath)
	if err != nil {
		return fmt.Errorf("failed to read config file: %w", err)
	}

	var config PoolConfiguration
	if err := yaml.Unmarshal(data, &config); err != nil {
		return fmt.Errorf("failed to parse YAML config: %w", err)
	}

	poolConfig = &config
	return nil
}

// GetPoolTypes returns all available pool types from configuration
func GetPoolTypes() []string {
	if poolConfig == nil {
		return []string{"AllyHub Desktop App"} // fallback
	}

	types := make([]string, len(poolConfig.PoolTypes))
	for i, poolType := range poolConfig.PoolTypes {
		types[i] = poolType.Name
	}
	return types
}

// GetEndpointsForPoolType returns predefined endpoints for a specific pool type
func GetEndpointsForPoolType(poolType string) []EndpointConfig {
	if poolConfig == nil {
		return []EndpointConfig{} // fallback
	}

	for _, pt := range poolConfig.PoolTypes {
		if pt.Name == poolType {
			return pt.Endpoints
		}
	}
	return []EndpointConfig{}
}

// ValidatePoolType checks if a pool type is valid according to configuration
func ValidatePoolType(poolType string) bool {
	if poolConfig == nil {
		return poolType == "AllyHub Desktop App" // fallback
	}

	for _, pt := range poolConfig.PoolTypes {
		if pt.Name == poolType {
			return true
		}
	}
	return false
}

// GetDefaultPoolType returns the first pool type from configuration
func GetDefaultPoolType() string {
	if poolConfig == nil || len(poolConfig.PoolTypes) == 0 {
		return "AllyHub Desktop App" // fallback
	}
	return poolConfig.PoolTypes[0].Name
}