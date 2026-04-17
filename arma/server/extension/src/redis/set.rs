//! Redis set operations for unique collections and membership tracking.

use crate::redis_operation;
use bb8_redis::redis::AsyncCommands;

/// Adds a value to a Redis set.
pub fn set_add(key: String, value: String) -> String {
    redis_operation!(conn => {
        match conn.sadd::<_, _, i32>(&key, &value).await {
            Ok(added) => added.to_string(),
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Retrieves all members of a Redis set.
pub fn set_members(key: String) -> String {
    redis_operation!(conn => {
        match conn.smembers::<_, Vec<String>>(&key).await {
            Ok(members) => members.join(","),
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Returns the number of members in a Redis set (cardinality).
pub fn set_card(key: String) -> String {
    redis_operation!(conn => {
        match conn.scard::<_, i32>(&key).await {
            Ok(card) => card.to_string(),
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Removes a value from a Redis set.
pub fn set_del(key: String, value: String) -> String {
    redis_operation!(conn => {
        match conn.srem::<_, _, i32>(&key, &value).await {
            Ok(removed) => removed.to_string(),
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Tests if a value is a member of a Redis set.
pub fn set_is_member(key: String, value: String) -> String {
    redis_operation!(conn => {
        match conn.sismember::<_, _, bool>(&key, &value).await {
            Ok(is_member) => if is_member { "1" } else { "0" }.to_string(),
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Removes and returns a random member from a Redis set.
pub fn set_pop(key: String) -> String {
    redis_operation!(conn => {
        match conn.spop::<_, String>(&key).await {
            Ok(value) => value,
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Returns a random member from a Redis set without removing it.
pub fn set_random_member(key: String) -> String {
    redis_operation!(conn => {
        match conn.srandmember::<_, String>(&key).await {
            Ok(value) => value,
            Err(e) => format!("Error: {}", e),
        }
    })
}

/// Returns multiple random members from a Redis set without removing them.
pub fn set_random_members(key: String, count: isize) -> String {
    redis_operation!(conn => {
        match conn
            .srandmember_multiple::<_, Vec<String>>(&key, count.try_into().unwrap_or(0))
            .await
        {
            Ok(values) => values.join(","),
            Err(e) => format!("Error: {}", e),
        }
    })
}
