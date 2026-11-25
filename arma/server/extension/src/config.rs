//! Extension configuration: the forge-webapi connection (`[api]`)
//! and the SurrealDB connection (`[surreal]`).
//!
//! The API is the extension's only persistence backend. `[surreal]`
//! is kept only for the one-time migration of legacy data: the
//! `Legacy*Repository` types in `storage/` read a legacy row once so
//! it can be moved into the API, then delete it. Once migration is
//! confirmed done, the SurrealDB connection can be removed entirely.

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
    #[serde(default)]
    pub api: ApiConfig,
}

/// Configuration for the forge-webapi (`[api]` in config.toml).
///
/// The API is the extension's only persistence backend — there is no
/// on/off switch and no fallback. `[api]` just holds the connection
/// details. The API must be running before the game starts (in
/// forge-webapi: `docker compose up`, then `curl
/// localhost:8080/health`); if the client cannot be built, every
/// persistence operation fails loudly instead of silently using
/// another backend.
///
/// Each field has a serde default matching `Default`, so a partial
/// `[api]` section (e.g. only `base_url`) cannot fail the whole
/// config parse and silently fall back to defaults.
#[derive(Debug, Clone, Deserialize)]
pub struct ApiConfig {
    #[serde(default = "ApiConfig::default_base_url")]
    pub base_url: String,
    #[serde(default = "ApiConfig::default_timeout_ms")]
    pub timeout_ms: Option<u64>,
}

impl ApiConfig {
    fn default_base_url() -> String {
        "http://127.0.0.1:8080".to_string()
    }

    fn default_timeout_ms() -> Option<u64> {
        Some(5000)
    }
}

impl Default for ApiConfig {
    fn default() -> Self {
        Self {
            base_url: Self::default_base_url(),
            timeout_ms: Self::default_timeout_ms(),
        }
    }
}

/// SurrealDB connection (`[surreal]` in config.toml).
///
/// Migration-only: the `Legacy*Repository` types in `storage/` read
/// legacy rows through this connection so they can be moved into the
/// API. Nothing else uses it — the extension no longer defines
/// SurrealDB tables or persists through it.
#[derive(Debug, Clone, Deserialize)]
pub struct SurrealConfig {
    #[serde(default = "SurrealConfig::default_endpoint")]
    pub endpoint: String,
    #[serde(default = "SurrealConfig::default_namespace")]
    pub namespace: String,
    #[serde(default = "SurrealConfig::default_database")]
    pub database: String,
    #[serde(default = "SurrealConfig::default_username")]
    pub username: Option<String>,
    #[serde(default = "SurrealConfig::default_password")]
    pub password: Option<String>,
    #[serde(default = "SurrealConfig::default_connect_timeout_ms")]
    pub connect_timeout_ms: Option<u64>,
}

impl SurrealConfig {
    fn default_endpoint() -> String {
        "127.0.0.1:8000".to_string()
    }

    fn default_namespace() -> String {
        "forge".to_string()
    }

    fn default_database() -> String {
        "main".to_string()
    }

    fn default_username() -> Option<String> {
        Some("root".to_string())
    }

    fn default_password() -> Option<String> {
        Some("root".to_string())
    }

    fn default_connect_timeout_ms() -> Option<u64> {
        Some(5000)
    }
}

impl Default for SurrealConfig {
    fn default() -> Self {
        Self {
            endpoint: Self::default_endpoint(),
            namespace: Self::default_namespace(),
            database: Self::default_database(),
            username: Self::default_username(),
            password: Self::default_password(),
            connect_timeout_ms: Self::default_connect_timeout_ms(),
        }
    }
}

pub fn load() -> Config {
    CONFIG_CACHE
        .get_or_init(|| {
            let config_path = locate_config_path();

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

fn locate_config_path() -> PathBuf {
    let mut candidates = Vec::new();

    if let Ok(cwd) = std::env::current_dir() {
        candidates.push(cwd.join("@forge_server").join("config.toml"));
        candidates.push(cwd.join("config.toml"));
    }

    if let Ok(exe) = std::env::current_exe() {
        if let Some(dir) = exe.parent() {
            candidates.push(dir.join("@forge_server").join("config.toml"));
            candidates.push(dir.join("config.toml"));
        }
    }

    candidates
        .into_iter()
        .find(|path| path.exists())
        .unwrap_or_else(|| PathBuf::from("@forge_server/config.toml"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn partial_api_section_fills_missing_fields_from_defaults() {
        let config: Config =
            toml::from_str("[surreal]\nendpoint = \"127.0.0.1:8000\"\n\n[api]\nbase_url = \"http://127.0.0.1:8080\"\n")
                .expect("partial [api] section should parse");
        assert_eq!(config.api.base_url, "http://127.0.0.1:8080");
        assert_eq!(config.api.timeout_ms, Some(5000));
        // A partial [surreal] section gets defaults too.
        assert_eq!(config.surreal.namespace, "forge");
        assert_eq!(config.surreal.database, "main");
    }

    #[test]
    fn missing_api_section_uses_defaults() {
        let config: Config = toml::from_str("[surreal]\nendpoint = \"127.0.0.1:8000\"\n")
            .expect("missing [api] section should parse");
        assert_eq!(config.api.base_url, "http://127.0.0.1:8080");
    }
}
