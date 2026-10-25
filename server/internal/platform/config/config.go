package config

import "os"

type Config struct {
	Environment string
	HTTPAddress string
	DatabaseURL string
}

func FromEnvironment() Config {
	return Config{
		Environment: valueOrDefault("GOSHIPKIT_ENV", "development"),
		HTTPAddress: valueOrDefault("GOSHIPKIT_HTTP_ADDR", ":8080"),
		DatabaseURL: os.Getenv("GOSHIPKIT_DATABASE_URL"),
	}
}

func valueOrDefault(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}
