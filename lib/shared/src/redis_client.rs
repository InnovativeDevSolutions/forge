/// Redis client abstraction for dependency injection
pub trait RedisClient: Send + Sync {
    // Hash operations
    fn hash_mset(&self, key: String, fields: Vec<(String, String)>) -> Result<(), String>;
    fn hash_get_all(&self, key: String) -> Result<String, String>;
    fn hash_get(&self, key: String, field: String) -> Result<String, String>;
    fn hash_del(&self, key: String, field: String) -> Result<(), String>;

    // List operations
    fn list_rpush(&self, key: String, value: String) -> Result<(), String>;
    fn list_range(&self, key: String, start: isize, end: isize) -> Result<Vec<String>, String>;
    fn list_del(&self, key: String, count: isize, value: String) -> Result<(), String>;

    // Set operations
    fn set_add(&self, key: String, member: String) -> Result<(), String>;
    fn set_members(&self, key: String) -> Result<Vec<String>, String>;
    fn set_del(&self, key: String, member: String) -> Result<(), String>;

    // Common operations
    fn get_key(&self, key: String) -> Result<String, String>;
    fn set_key(&self, key: String, value: String) -> Result<(), String>;
    fn incr_key(&self, key: String, count: usize) -> Result<i64, String>;
    fn key_exists(&self, key: String) -> Result<bool, String>;
    fn delete_key(&self, key: String) -> Result<(), String>;
}

/// Converts a JSON value to a Redis-compatible string format.
pub fn parse_json_value(value: &serde_json::Value) -> String {
    let wrapped = serde_json::Value::Array(vec![value.clone()]);
    wrapped.to_string()
}

/// Converts a Redis string value back to a JSON value with intelligent type detection.
pub fn parse_redis_value(value: &str) -> serde_json::Value {
    // Handle empty values
    if value.is_empty() {
        return serde_json::Value::Null;
    }

    // Try to parse as JSON first
    if let Ok(json_val) = serde_json::from_str(value) {
        // Special handling for single-element arrays (unwrap them)
        if let serde_json::Value::Array(arr) = &json_val {
            if arr.len() == 1 {
                return arr[0].clone();
            }
        }
        return json_val;
    }

    // Try to parse as integer
    if let Ok(int_val) = value.parse::<i64>() {
        return serde_json::Value::Number(serde_json::Number::from(int_val));
    }

    // Try to parse as float
    if let Ok(float_val) = value.parse::<f64>() {
        if let Some(num) = serde_json::Number::from_f64(float_val) {
            return serde_json::Value::Number(num);
        }
    }

    // Try to parse as boolean (case-insensitive)
    match value.to_lowercase().as_str() {
        "true" => serde_json::Value::Bool(true),
        "false" => serde_json::Value::Bool(false),
        // Default to string if no other type matches
        _ => serde_json::Value::String(value.to_string()),
    }
}
