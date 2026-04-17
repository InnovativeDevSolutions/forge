//! Redis list operations for ordered collections and queues.

use crate::redis_operation;
use bb8_redis::redis::AsyncCommands;

/// Sets the value of an element at a specific index in a Redis list.
pub fn list_set(key: String, index: isize, value: String) -> String {
    use crate::redis::helpers::encode_b64;
    let encoded_value = encode_b64(&value);
    redis_operation!(conn => {
        match conn.lset(&key, index, &encoded_value).await {
            Ok(()) => "OK".to_string(),
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Retrieves the value of an element at a specific index in a Redis list.
pub fn list_get(key: String, index: isize) -> String {
    use crate::redis::helpers::decode_b64;
    redis_operation!(conn => {
        match conn.lindex::<_, String>(&key, index).await {
            Ok(encoded_value) => {
                match decode_b64(&encoded_value) {
                    Ok(decoded) => decoded,
                    Err(e) => format!("Error decoding base64: {}", e),
                }
            },
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Returns the length (number of elements) of a Redis list.
pub fn list_len(key: String) -> String {
    redis_operation!(conn => {
        match conn.llen::<_, i32>(&key).await {
            Ok(len) => len.to_string(),
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Retrieves a range of elements from a Redis list.
pub fn list_range(key: String, start: isize, end: isize) -> String {
    use crate::redis::helpers::decode_b64;
    redis_operation!(conn => {
        match conn.lrange::<_, Vec<String>>(&key, start, end).await {
            Ok(encoded_values) => {
                let mut decoded_values = Vec::new();
                for encoded in encoded_values {
                    match decode_b64(&encoded) {
                        Ok(decoded) => decoded_values.push(decoded),
                        Err(e) => return format!("Error decoding base64: {}", e),
                    }
                }
                match serde_json::to_string(&decoded_values) {
                    Ok(json_array) => json_array,
                    Err(e) => format!("Error: Failed to serialize to JSON: {}", e),
                }
            },
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Prepends a value to the beginning (left) of a Redis list.
pub fn list_lpush(key: String, value: String) -> String {
    use crate::redis::helpers::encode_b64;
    let encoded_value = encode_b64(&value);
    redis_operation!(conn => {
        match conn.lpush::<_, _, usize>(&key, &encoded_value).await {
            Ok(len) => len.to_string(),
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Appends a value to the end (right) of a Redis list.
pub fn list_rpush(key: String, value: String) -> String {
    use crate::redis::helpers::encode_b64;
    let encoded_value = encode_b64(&value);
    redis_operation!(conn => {
        match conn.rpush::<_, _, usize>(&key, &encoded_value).await {
            Ok(len) => len.to_string(),
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Removes and returns elements from the beginning (left) of a Redis list.
pub fn list_lpop(key: String, count: usize) -> String {
    use crate::redis::helpers::decode_b64;
    redis_operation!(conn => {
        let count_option = if count == 0 {
            None
        } else {
            std::num::NonZeroUsize::new(count)
        };
        match conn.lpop::<_, Vec<String>>(&key, count_option).await {
            Ok(encoded_values) => {
                let mut decoded_values = Vec::new();
                for encoded in encoded_values {
                    match decode_b64(&encoded) {
                        Ok(decoded) => decoded_values.push(decoded),
                        Err(e) => return format!("Error decoding base64: {}", e),
                    }
                }
                match serde_json::to_string(&decoded_values) {
                    Ok(json_array) => json_array,
                    Err(e) => format!("Error: Failed to serialize to JSON: {}", e),
                }
            },
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Removes and returns elements from the end (right) of a Redis list.
pub fn list_rpop(key: String, count: usize) -> String {
    use crate::redis::helpers::decode_b64;
    redis_operation!(conn => {
        let count_option = if count == 0 {
            None
        } else {
            std::num::NonZeroUsize::new(count)
        };
        match conn.rpop::<_, Vec<String>>(&key, count_option).await {
            Ok(encoded_values) => {
                let mut decoded_values = Vec::new();
                for encoded in encoded_values {
                    match decode_b64(&encoded) {
                        Ok(decoded) => decoded_values.push(decoded),
                        Err(e) => return format!("Error decoding base64: {}", e),
                    }
                }
                match serde_json::to_string(&decoded_values) {
                    Ok(json_array) => json_array,
                    Err(e) => format!("Error: Failed to serialize to JSON: {}", e),
                }
            },
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Trims a Redis list to keep only elements within the specified range.
pub fn list_trim(key: String, start: isize, end: isize) -> String {
    redis_operation!(conn => {
        match conn.ltrim(&key, start, end).await {
            Ok(()) => "OK".to_string(),
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Removes elements from a Redis list by value.
pub fn list_del(key: String, count: isize, value: String) -> String {
    use crate::redis::helpers::encode_b64;
    let encoded_value = encode_b64(&value);
    redis_operation!(conn => {
        match conn.lrem::<_, _, i32>(&key, count, &encoded_value).await {
            Ok(removed) => removed.to_string(),
            Err(e) => format!("Error: {}", e),
        }
    })
}
