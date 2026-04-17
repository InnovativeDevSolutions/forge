//! Redis hash operations for structured data storage.

use crate::redis_operation;
use bb8_redis::redis::AsyncCommands;
use std::collections::HashMap;

/// Sets a single field in a Redis hash.
pub fn hash_set(key: String, field: String, value: String) -> String {
    redis_operation!(conn => {
        match conn.hset::<_, _, _, i32>(&key, &field, &value).await {
            Ok(added) => added.to_string(),
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Sets multiple fields in a Redis hash atomically.
pub fn hash_mset(key: String, items: Vec<(String, String)>) -> String {
    redis_operation!(conn => {
        match conn.hset_multiple(&key, &items).await {
            Ok(()) => "OK".to_string(),
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Retrieves the value of a specific field from a Redis hash.
pub fn hash_get(key: String, field: String) -> String {
    redis_operation!(conn => {
        match conn.hget::<_, _, Option<String>>(&key, &field).await {
            Ok(Some(value)) => value,
            Ok(None) => String::new(),
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Retrieves all fields and values from a Redis hash.
pub fn hash_get_all(key: String) -> String {
    redis_operation!(conn => {
        match conn.hgetall::<_, HashMap<String, String>>(&key).await {
            Ok(hash_map) => match serde_json::to_string(&hash_map) {
                Ok(json) => json,
                Err(e) => format!("Error: Failed to serialize hash map: {}", e),
            },
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Removes a field from a Redis hash.
pub fn hash_del(key: String, field: String) -> String {
    redis_operation!(conn => {
        match conn.hdel::<_, _, i32>(&key, &field).await {
            Ok(removed) => removed.to_string(),
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Retrieves all field names from a Redis hash.
pub fn hash_keys(key: String) -> String {
    redis_operation!(conn => {
        match conn.hkeys::<_, Vec<String>>(&key).await {
            Ok(fields) => fields.join(","),
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Retrieves all values from a Redis hash.
pub fn hash_values(key: String) -> String {
    redis_operation!(conn => {
        match conn.hvals::<_, Vec<String>>(&key).await {
            Ok(values) => values.join(","),
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Returns the number of fields in a Redis hash.
pub fn hash_len(key: String) -> String {
    redis_operation!(conn => {
        match conn.hlen::<_, i32>(&key).await {
            Ok(len) => len.to_string(),
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Tests if a field exists in a Redis hash.
pub fn hash_exists(key: String, field: String) -> String {
    redis_operation!(conn => {
        match conn.hexists::<_, _, bool>(&key, &field).await {
            Ok(exists) => if exists { "1" } else { "0" }.to_string(),
            Err(e) => format!("Error: {}", e),
        }
    })
}
