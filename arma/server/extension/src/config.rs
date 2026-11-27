//! Extension configuration: the forge-webapi connection (`[api]`).
//!
//! The API is the extension's only persistence backend. Unknown
//! sections (an old `[surreal]` section, or the shared Forge Host
//! config's extra sections) are ignored.

use serde::Deserialize;
use std::fs;
use std::path::PathBuf;
use std::sync::OnceLock;

use crate::log::log;

static CONFIG_CACHE: OnceLock<Config> = OnceLock::new();

#[derive(Debug, Clone, Deserialize, Default)]
pub struct Config {
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
        let config: Config = toml::from_str("[api]\nbase_url = \"http://10.0.0.5:8080\"\n")
            .expect("partial [api] section should parse");
        assert_eq!(config.api.base_url, "http://10.0.0.5:8080");
        assert_eq!(config.api.timeout_ms, Some(5000));
    }

    #[test]
    fn missing_api_section_uses_defaults() {
        let config: Config =
            toml::from_str("").expect("an empty config should parse");
        assert_eq!(config.api.base_url, "http://127.0.0.1:8080");
    }

    #[test]
    fn old_surreal_section_is_ignored() {
        // Configs written for older builds still carry [surreal]; they
        // must keep parsing instead of falling back to defaults.
        let config: Config = toml::from_str(
            "[surreal]\nendpoint = \"127.0.0.1:8000\"\npassword = \"root\"\n\n[api]\nbase_url = \"http://10.0.0.5:8080\"\n",
        )
        .expect("an old [surreal] section should be ignored");
        assert_eq!(config.api.base_url, "http://10.0.0.5:8080");
    }
}
