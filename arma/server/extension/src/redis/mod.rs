//! Redis operations and utilities for the Arma 3 server extension.

use arma_rs::Group;
use tokio::time::{Duration, timeout};

pub use client::create_redis_pool;
pub use config::RedisConfig;
pub use helpers::{decode_b64, encode_b64};

use crate::{CONNECTION_STATE, ConnectionState, REDIS_POOL, log};

pub mod client;
pub mod common;
pub mod config;
pub mod hash;
pub mod helpers;
pub mod list;
pub mod macros;
pub mod set;

/// Initialize Redis connection pool with fallback to default config
///
/// This function attempts to connect to Redis using the provided config,
/// with a 5-second timeout. If the primary config fails, it tries the
/// default config as a fallback.
pub async fn initialize(config: RedisConfig) {
    // Use timeout to prevent hanging if Redis is unavailable
    let pool_result = timeout(Duration::from_secs(5), create_redis_pool(&config)).await;

    let pool = match pool_result {
        Err(_) => {
            log::log(
                "redis",
                "ERROR",
                "Redis connection timed out after 5 seconds",
            );
            *CONNECTION_STATE.write().unwrap() = ConnectionState::Failed;
            return; // Exit early
        }
        Ok(Ok(pool)) => {
            log::log("redis", "INFO", "Connected to Redis server");
            pool
        }
        Ok(Err(e)) => {
            log::log(
                "redis",
                "WARN",
                &format!("Failed to connect to Redis (primary config): {}", e),
            );
            // Try default config as fallback with timeout
            let default_config = RedisConfig::default();
            match timeout(Duration::from_secs(5), create_redis_pool(&default_config)).await {
                Err(_) => {
                    log::log(
                        "redis",
                        "ERROR",
                        "Redis (default config) timed out after 5 seconds",
                    );
                    *CONNECTION_STATE.write().unwrap() = ConnectionState::Failed;
                    return;
                }
                Ok(Ok(pool)) => {
                    log::log("redis", "INFO", "Connected to Redis using default config");
                    pool
                }
                Ok(Err(e)) => {
                    log::log(
                        "redis",
                        "ERROR",
                        &format!("Failed to connect to Redis (all attempts): {}", e),
                    );
                    *CONNECTION_STATE.write().unwrap() = ConnectionState::Failed;
                    return; // Exit early, don't set pool
                }
            }
        }
    };

    if REDIS_POOL.set(pool).is_ok() {
        *CONNECTION_STATE.write().unwrap() = ConnectionState::Connected;
    } else {
        log::log("redis", "ERROR", "Failed to set Redis pool (already set)");
        *CONNECTION_STATE.write().unwrap() = ConnectionState::Failed;
    }
}

pub fn group() -> Group {
    Group::new()
        .group(
            "common",
            Group::new()
                .command("set", common::set_key)
                .command("get", common::get_key)
                .command("incr", common::incr_key)
                .command("decr", common::decr_key)
                .command("del", common::delete_key)
                .command("keys", common::list_keys),
        )
        .group(
            "hash",
            Group::new()
                .command("set", hash::hash_set)
                .command("mset", hash::hash_mset)
                .command("get", hash::hash_get)
                .command("getall", hash::hash_get_all)
                .command("del", hash::hash_del)
                .command("keys", hash::hash_keys)
                .command("vals", hash::hash_values)
                .command("len", hash::hash_len)
                .command("exists", hash::hash_exists),
        )
        .group(
            "list",
            Group::new()
                .command("set", list::list_set)
                .command("get", list::list_get)
                .command("len", list::list_len)
                .command("range", list::list_range)
                .command("lpush", list::list_lpush)
                .command("rpush", list::list_rpush)
                .command("lpop", list::list_lpop)
                .command("rpop", list::list_rpop)
                .command("trim", list::list_trim)
                .command("del", list::list_del),
        )
        .group(
            "set",
            Group::new()
                .command("add", set::set_add)
                .command("members", set::set_members)
                .command("card", set::set_card)
                .command("ismember", set::set_is_member)
                .command("randmember", set::set_random_member)
                .command("randmembers", set::set_random_members)
                .command("pop", set::set_pop)
                .command("del", set::set_del),
        )
}
