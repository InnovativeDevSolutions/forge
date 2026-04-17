//! Helper utilities for Redis data processing and encoding.

use serde_json;

/// Intelligently parses a Redis string value into the appropriate JSON type.
#[allow(dead_code)]
pub fn parse_redis_value(value: &str) -> serde_json::Value {
    // Handle empty strings as null values
    if value.is_empty() {
        return serde_json::Value::Null;
    }

    // Try to parse as JSON first (handles objects, arrays, and JSON primitives)
    if let Ok(json_val) = serde_json::from_str(value) {
        // Special handling: unwrap single-element arrays
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
        "true" => return serde_json::Value::Bool(true),
        "false" => return serde_json::Value::Bool(false),
        _ => {}
    }

    // Fallback: treat as string
    serde_json::Value::String(value.to_string())
}

/// Converts a JSON value to a string by wrapping it in an array.
#[allow(dead_code)]
pub fn parse_json_value(value: &serde_json::Value) -> String {
    // Wrap the value in a single-element array
    let wrapped = serde_json::Value::Array(vec![value.clone()]);

    // Serialize the wrapped array to a JSON string
    wrapped.to_string()
}

/// Encodes a string to base64 for safe Redis storage.
pub fn encode_b64(data: &str) -> String {
    use base64::{Engine as _, engine::general_purpose};
    general_purpose::STANDARD.encode(data.as_bytes())
}

/// Decodes a base64 string back to its original form.
pub fn decode_b64(encoded: &str) -> Result<String, String> {
    use base64::{Engine as _, engine::general_purpose};
    match general_purpose::STANDARD.decode(encoded) {
        Ok(bytes) => match String::from_utf8(bytes) {
            Ok(string) => Ok(string),
            Err(e) => Err(format!("Invalid UTF-8: {}", e)),
        },
        Err(e) => Err(format!("Invalid base64: {}", e)),
    }
}
