//! Configuration management for Redis connection and application settings.

use serde::Deserialize;
use std::fs;
use std::path::PathBuf;
use std::sync::OnceLock;

use crate::log::log;

static CONFIG_CACHE: OnceLock<Config> = OnceLock::new();

/// Main configuration structure for the entire application.
#[derive(Debug, Clone, Deserialize)]
pub struct Config {
    /// Durable storage backend selector.
    #[serde(default)]
    pub storage: StorageConfig,
    /// Redis configuration with automatic defaults if not specified
    #[serde(default)]
    pub redis: RedisConfig,
    /// SurrealDB configuration with automatic defaults if not specified
    #[serde(default)]
    pub surreal: SurrealConfig,
}

impl Default for Config {
    /// Creates a default configuration with sensible values for development.
    fn default() -> Self {
        Self {
            storage: StorageConfig::default(),
            redis: RedisConfig::default(),
            surreal: SurrealConfig::default(),
        }
    }
}

#[derive(Debug, Clone, Copy, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum StorageBackend {
    Redis,
    Surreal,
}

impl Default for StorageBackend {
    fn default() -> Self {
        Self::Redis
    }
}

/// Durable storage backend selection.
#[derive(Debug, Clone, Deserialize)]
pub struct StorageConfig {
    #[serde(default)]
    pub backend: StorageBackend,
}

impl Default for StorageConfig {
    fn default() -> Self {
        Self {
            backend: StorageBackend::Redis,
        }
    }
}

/// Redis connection and connection pool configuration.
#[derive(Debug, Clone, Deserialize)]
pub struct RedisConfig {
    /// Redis server hostname or IP address
    pub host: String,
    /// Redis server port number
    pub port: u16,
    /// Redis database number (0-15)
    pub db: u8,
    /// Username for Redis ACL authentication (Redis 6.0+)
    pub username: Option<String>,
    /// Password for Redis authentication
    pub password: Option<String>,
    /// Maximum number of connections in the pool
    pub max_connections: Option<usize>,
    /// Minimum number of idle connections to maintain
    pub min_connections: Option<usize>,
    /// Idle connection timeout in seconds
    pub idle_timeout: Option<u64>,
    /// Maximum time to wait for pool connection checkout in milliseconds
    pub pool_get_timeout_ms: Option<u64>,
    /// Maximum time to wait for individual Redis command execution in milliseconds
    pub command_timeout_ms: Option<u64>,
    /// Maximum time to wait for pool connection establishment in milliseconds
    pub connect_timeout_ms: Option<u64>,
}

impl Default for RedisConfig {
    /// Creates default Redis configuration suitable for local development.
    fn default() -> Self {
        Self {
            host: "127.0.0.1".to_string(),
            port: 6379,
            db: 0,
            username: None,
            password: None,
            max_connections: Some(10),
            min_connections: Some(2),
            idle_timeout: Some(60),
            pool_get_timeout_ms: Some(2000),
            command_timeout_ms: Some(2000),
            connect_timeout_ms: Some(2000),
        }
    }
}

/// SurrealDB connection configuration.
#[derive(Debug, Clone, Deserialize)]
pub struct SurrealConfig {
    /// SurrealDB HTTP endpoint, for example `127.0.0.1:8000`.
    pub endpoint: String,
    /// SurrealDB namespace.
    pub namespace: String,
    /// SurrealDB database.
    pub database: String,
    /// Optional root username for authentication.
    pub username: Option<String>,
    /// Optional root password for authentication.
    pub password: Option<String>,
    /// Maximum time to wait for initial connection in milliseconds.
    pub connect_timeout_ms: Option<u64>,
}

impl Default for SurrealConfig {
    fn default() -> Self {
        Self {
            endpoint: "127.0.0.1:8000".to_string(),
            namespace: "forge".to_string(),
            database: "main".to_string(),
            username: Some("root".to_string()),
            password: Some("root".to_string()),
            connect_timeout_ms: Some(5000),
        }
    }
}

impl RedisConfig {
    /// Generates a Redis connection string from the configuration.
    pub fn connection_string(&self) -> String {
        // Build authentication part of the URL
        let auth_part = match (&self.username, &self.password) {
            (Some(username), Some(password)) => format!("{}:{}@", username, password),
            (None, Some(password)) => format!(":{}@", password),
            (Some(username), None) => format!("{}@", username),
            (None, None) => String::new(),
        };

        let mut conn_str = format!("redis://{}{}", auth_part, self.host);

        if self.port != 6379 {
            conn_str.push_str(&format!(":{}", self.port));
        }

        if self.db != 0 {
            conn_str.push_str(&format!("/{}", self.db));
        }

        log(
            "main",
            "INFO",
            &format!("Redis connection string: {}", conn_str),
        );

        conn_str
    }
}

/// Loads configuration from the `config.toml` file with graceful fallback to defaults.
pub fn load() -> Config {
    CONFIG_CACHE
        .get_or_init(|| {
            let config_path = std::env::current_exe()
                .ok()
                .and_then(|exe| {
                    exe.parent()
                        .map(|dir| dir.join("@forge_server").join("config.toml"))
                })
                .filter(|p| p.exists())
                .unwrap_or_else(|| PathBuf::from("@forge_server/config.toml"));

            match fs::read_to_string(&config_path) {
                Ok(contents) => {
                    log("main", "INFO", &format!("Config file found! Loading..."));
                    match toml::from_str::<Config>(&contents) {
                        Ok(config) => config,
                        Err(error) => {
                            log(
                                "main",
                                "ERROR",
                                &format!(
                                    "Failed to parse config file '{}': {}. Using defaults.",
                                    config_path.display(),
                                    error
                                ),
                            );
                            Config::default()
                        }
                    }
                }
                Err(_) => {
                    log(
                        "main",
                        "INFO",
                        &format!("Config file not found. Using default configuration."),
                    );
                    Config::default()
                }
            }
        })
        .clone()
}
