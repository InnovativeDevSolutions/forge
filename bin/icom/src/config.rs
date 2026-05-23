/// Configuration management for ICOM server.
use serde::Deserialize;
use std::fs;
use std::path::PathBuf;

/// ICOM server configuration.
#[derive(Debug, Clone, Deserialize, Default)]
pub struct Config {
    /// Server bind address configuration
    #[serde(default)]
    pub server: ServerConfig,
}

/// Server bind configuration.
#[derive(Debug, Clone, Deserialize)]
pub struct ServerConfig {
    /// Host to bind to (e.g., "0.0.0.0" for all interfaces, "127.0.0.1" for localhost only)
    #[serde(default = "default_host")]
    pub host: String,
    /// Port to listen on
    #[serde(default = "default_port")]
    pub port: u16,
}

impl Default for ServerConfig {
    fn default() -> Self {
        Self {
            host: default_host(),
            port: default_port(),
        }
    }
}

impl ServerConfig {
    /// Returns the full bind address as "host:port"
    pub fn bind_address(&self) -> String {
        format!("{}:{}", self.host, self.port)
    }
}

fn default_host() -> String {
    "0.0.0.0".to_string()
}

fn default_port() -> u16 {
    9090
}

/// Loads configuration from config.toml with graceful fallback to defaults.
///
/// Looks for config.toml in:
/// 1. Current directory
/// 2. Executable directory
///
/// If no config file is found, uses default values.
pub fn load() -> Config {
    // Try current directory first
    let config_path = PathBuf::from("config.toml");

    let config_path = if config_path.exists() {
        config_path
    } else {
        // Try executable directory
        std::env::current_exe()
            .ok()
            .and_then(|exe| exe.parent().map(|dir| dir.join("config.toml")))
            .filter(|p| p.exists())
            .unwrap_or_else(|| PathBuf::from("config.toml"))
    };

    match fs::read_to_string(&config_path) {
        Ok(contents) => {
            println!("Loading config from: {}", config_path.display());
            match toml::from_str::<Config>(&contents) {
                Ok(config) => {
                    println!("Configuration loaded successfully");
                    config
                }
                Err(e) => {
                    eprintln!("Failed to parse config.toml: {}", e);
                    eprintln!("Using default configuration");
                    Config::default()
                }
            }
        }
        Err(_) => {
            println!("No config.toml found, using defaults");
            Config::default()
        }
    }
}
