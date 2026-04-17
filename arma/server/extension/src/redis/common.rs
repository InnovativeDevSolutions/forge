//! Common Redis operations for basic key-value functionality.

use crate::redis_operation;
use bb8_redis::redis::AsyncCommands;

/// Sets a string value for the specified Redis key.
pub fn set_key(key: String, value: String) -> String {
    redis_operation!(conn => {
        match conn.set(&key, &value).await {
            Ok(()) => "OK".to_string(),
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Retrieves the string value for the specified Redis key.
pub fn get_key(key: String) -> String {
    redis_operation!(conn => {
        match conn.get::<_, String>(&key).await {
            Ok(value) => value,
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Increments a numeric value stored at the specified key.
pub fn incr_key(key: String, count: usize) -> String {
    redis_operation!(conn => {
        match conn.incr::<_, _, i64>(&key, count).await {
            Ok(value) => value.to_string(),
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Decrements a numeric value stored at the specified key.
pub fn decr_key(key: String, count: usize) -> String {
    redis_operation!(conn => {
        match conn.decr::<_, _, i64>(&key, count).await {
            Ok(value) => value.to_string(),
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Checks if a Redis key exists.
pub fn key_exists(key: String) -> String {
    redis_operation!(conn => {
        match conn.exists::<_, i32>(&key).await {
            Ok(exists) => exists.to_string(),
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Deletes a Redis key and its associated value.
pub fn delete_key(key: String) -> String {
    redis_operation!(conn => {
        match conn.del::<_, usize>(&key).await {
            Ok(removed) => removed.to_string(),
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Lists all Redis keys matching the wildcard pattern "*".
pub fn list_keys() -> String {
    redis_operation!(conn => {
        match conn.keys::<_, Vec<String>>("*").await {
            Ok(keys) => keys.join(","),
            Err(e) => format!("Error: {}", e),
        }
    })
}
