//! Extension configuration for SurrealDB-backed persistence.

use serde::Deserialize;
use std::fs;
use std::path::PathBuf;
use std::sync::OnceLock;

use crate::log::log;

static CONFIG_CACHE: OnceLock<Config> = OnceLock::new();

#[derive(Debug, Clone, Deserialize, Default)]
pub struct Config {
    #[serde(default)]
    pub surreal: SurrealConfig,
}

#[derive(Debug, Clone, Deserialize)]
pub struct SurrealConfig {
    pub endpoint: String,
    pub namespace: String,
    pub database: String,
    pub username: Option<String>,
    pub password: Option<String>,
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

pub fn load() -> Config {
    CONFIG_CACHE
        .get_or_init(|| {
            let config_path = std::env::current_exe()
                .ok()
                .and_then(|exe| {
                    exe.parent()
                        .map(|dir| dir.join("@forge_server").join("config.toml"))
                })
                .filter(|path| path.exists())
                .unwrap_or_else(|| PathBuf::from("@forge_server/config.toml"));

            match fs::read_to_string(&config_path) {
                Ok(contents) => {
                    log("main", "INFO", "Config file found. Loading.");
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
                    log("main", "INFO", "Config file not found. Using defaults.");
                    Config::default()
                }
            }
        })
        .clone()
}
