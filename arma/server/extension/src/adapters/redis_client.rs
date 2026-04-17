use crate::log::log;
use crate::redis;
use forge_shared::RedisClient;

/// Redis client implementation that bridges the repository layer with the extension's Redis module.
pub struct ExtensionRedisClient;

impl ExtensionRedisClient {
    /// Creates a new instance of the Redis client adapter.
    pub fn new() -> Self {
        Self
    }
}

impl RedisClient for ExtensionRedisClient {
    /// Sets multiple fields in a Redis hash.
    fn hash_mset(&self, key: String, fields: Vec<(String, String)>) -> Result<(), String> {
        let result = redis::hash::hash_mset(key, fields);
        log("debug", "DEBUG", &result);

        if result == "OK" { Ok(()) } else { Err(result) }
    }

    /// Retrieves all fields and values from a Redis hash.
    fn hash_get_all(&self, key: String) -> Result<String, String> {
        let result = redis::hash::hash_get_all(key);
        log("debug", "DEBUG", &result);

        if result.starts_with("Error:") {
            Err(result)
        } else {
            Ok(result)
        }
    }

    /// Retrieves a single field value from a Redis hash.
    fn hash_get(&self, key: String, field: String) -> Result<String, String> {
        let result = redis::hash::hash_get(key, field);
        log("debug", "DEBUG", &result);

        if result.starts_with("Error:") {
            Err(result)
        } else {
            Ok(result)
        }
    }

    /// Deletes a specific field from a Redis hash.
    fn hash_del(&self, key: String, field: String) -> Result<(), String> {
        let result = redis::hash::hash_del(key, field);
        log("debug", "DEBUG", &result);

        if result.starts_with("Error:") {
            Err(result)
        } else {
            Ok(())
        }
    }

    /// Appends a value to the end of a Redis list.
    fn list_rpush(&self, key: String, value: String) -> Result<(), String> {
        let result = redis::list::list_rpush(key, value);
        log("debug", "DEBUG", &result);

        if result.starts_with("Error:") {
            Err(result)
        } else {
            Ok(())
        }
    }

    /// Retrieves a range of elements from a Redis list.
    fn list_range(&self, key: String, start: isize, end: isize) -> Result<Vec<String>, String> {
        let result = redis::list::list_range(key, start, end);
        log("debug", "DEBUG", &result);

        if result.starts_with("Error:") {
            Err(result)
        } else {
            // Parse the JSON array response
            match serde_json::from_str::<Vec<String>>(&result) {
                Ok(values) => Ok(values),
                Err(e) => Err(format!("Failed to parse list response: {}", e)),
            }
        }
    }

    /// Removes elements from a Redis list by value.
    fn list_del(&self, key: String, count: isize, value: String) -> Result<(), String> {
        let result = redis::list::list_del(key, count, value);
        log("debug", "DEBUG", &result);

        if result.starts_with("Error:") {
            Err(result)
        } else {
            Ok(())
        }
    }

    /// # Set operations

    /// Adds a member to a Redis set.
    fn set_add(&self, key: String, member: String) -> Result<(), String> {
        let result = redis::set::set_add(key, member);
        log("debug", "DEBUG", &result);

        if result.starts_with("Error:") {
            Err(result)
        } else {
            Ok(())
        }
    }

    /// Retrieves all members from a Redis set.
    fn set_members(&self, key: String) -> Result<Vec<String>, String> {
        let result = redis::set::set_members(key);
        log("debug", "DEBUG", &result);

        if result.starts_with("Error:") {
            Err(result)
        } else if result.trim().is_empty() {
            Ok(Vec::new())
        } else {
            serde_json::from_str::<Vec<String>>(&result).or_else(|_| {
                Ok(result
                    .split(',')
                    .map(str::trim)
                    .filter(|value| !value.is_empty())
                    .map(ToString::to_string)
                    .collect())
            })
        }
    }

    /// Removes a member from a Redis set.
    fn set_del(&self, key: String, member: String) -> Result<(), String> {
        let result = redis::set::set_del(key, member);
        log("debug", "DEBUG", &result);

        if result.starts_with("Error:") {
            Err(result)
        } else {
            Ok(())
        }
    }

    /// Checks if a Redis key exists.
    fn key_exists(&self, key: String) -> Result<bool, String> {
        let result = redis::common::key_exists(key);
        log("debug", "DEBUG", &result);

        match result.as_str() {
            "1" => Ok(true),
            "0" => Ok(false),
            _ => Err(format!("Unexpected Redis response: {}", result)),
        }
    }

    /// Retrieves the value of a Redis key.
    fn get_key(&self, key: String) -> Result<String, String> {
        let result = redis::common::get_key(key);
        log("debug", "DEBUG", &result);

        if result.starts_with("Error:") {
            Err(result)
        } else {
            Ok(result)
        }
    }

    /// Sets a value in a Redis key.
    fn set_key(&self, key: String, value: String) -> Result<(), String> {
        let result = redis::common::set_key(key, value);
        log("debug", "DEBUG", &result);

        if result.starts_with("Error:") {
            Err(result)
        } else {
            Ok(())
        }
    }

    /// Increments a numeric Redis key.
    fn incr_key(&self, key: String, count: usize) -> Result<i64, String> {
        let result = redis::common::incr_key(key, count);
        log("debug", "DEBUG", &result);

        if result.starts_with("Error:") {
            Err(result)
        } else {
            result
                .parse::<i64>()
                .map_err(|error| format!("Failed to parse increment response: {}", error))
        }
    }

    /// Deletes a Redis key and all its associated data.
    fn delete_key(&self, key: String) -> Result<(), String> {
        let result = redis::common::delete_key(key);
        log("debug", "DEBUG", &result);

        if result.starts_with("Error:") {
            Err(result)
        } else {
            Ok(())
        }
    }
}
