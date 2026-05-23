pub mod validation;

pub use validation::{
    ActorValidationError, BankValidationError, GarageValidationError, LockerValidationError,
    OrgValidationError,
};

/// Converts an arma_rs::Value to a serde_json::Value.
///
/// This helper function is used to bridge the gap between Arma's SQF data types
/// and standard JSON, which is used for storage and API communication.
pub fn arma_value_to_json(arma_value: &arma_rs::Value) -> serde_json::Value {
    match arma_value {
        arma_rs::Value::String(s) => serde_json::Value::String(s.clone()),
        arma_rs::Value::Number(n) => serde_json::Number::from_f64(*n)
            .map(serde_json::Value::Number)
            .unwrap_or(serde_json::Value::Null),
        arma_rs::Value::Boolean(b) => serde_json::Value::Bool(*b),
        arma_rs::Value::Array(arr) => {
            let json_array: Vec<serde_json::Value> = arr.iter().map(arma_value_to_json).collect();
            serde_json::Value::Array(json_array)
        }
        arma_rs::Value::Null => serde_json::Value::Null,
        arma_rs::Value::Unknown(s) => serde_json::Value::String(s.clone()),
    }
}

/// Generates a phone number from a UID.
///
/// Uses the last 6 digits of the UID and prefixes with 0160.
pub fn generate_phone_number(uid: &str) -> String {
    let uid_chars: Vec<char> = uid.chars().collect();
    let uid_len = uid_chars.len();

    if uid_len >= 6 {
        let last_six: String = uid_chars[uid_len - 6..].iter().collect();
        format!("0160{}", last_six)
    } else {
        format!("0160{:0>6}", uid)
    }
}

/// Generates an email from a phone number.
///
/// Uses the phone number as the local part and @spearnet.mil as the domain.
pub fn generate_email(phone_number: &str) -> String {
    if phone_number.is_empty() {
        String::new()
    } else {
        format!("{}@spearnet.mil", phone_number)
    }
}
