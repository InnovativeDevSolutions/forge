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
    let config_path = locate_config_path();

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

fn locate_config_path() -> PathBuf {
    let mut candidates = Vec::new();

    if let Ok(cwd) = std::env::current_dir() {
        candidates.push(cwd.join("config.toml"));
        candidates.push(cwd.join("@forge_server").join("config.toml"));
    }

    if let Ok(exe) = std::env::current_exe() {
        if let Some(dir) = exe.parent() {
            candidates.push(dir.join("config.toml"));
            if let Some(parent) = dir.parent() {
                candidates.push(parent.join("config.toml"));
                candidates.push(parent.join("@forge_server").join("config.toml"));
            }
        }
    }

    candidates
        .into_iter()
        .find(|path| path.exists())
        .unwrap_or_else(|| PathBuf::from("config.toml"))
}
