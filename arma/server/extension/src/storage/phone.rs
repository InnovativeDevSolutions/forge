use super::*;
use crate::api::{ApiClient, encode_segment, phone_from_api_record, require_success};
use forge_models::PhonePayload;
use serde_json::Value as JsonValue;

/// Phone persistence through forge-webapi (`POST/GET/PUT/DELETE
/// /players/{uid}/phone` plus the contacts/messages/emails
/// sub-endpoints).
///
/// The API accepts client-supplied message/email ids and appends
/// idempotently per phone, and it indexes a send on both sides at
/// once — so `append_message` / `append_email` always POST to the
/// *sender's* phone (`message.from`, falling back to the `uid` the
/// service passed in); the service's second call for the other side
/// is then a no-op. The sender's copy is marked read by the API. The
/// service's two seed `add_contact` calls after `init` are idempotent.
pub struct ApiPhoneRepository {
    client: ApiClient,
}

impl ApiPhoneRepository {
    pub fn new() -> Result<Self, String> {
        Ok(Self {
            client: ApiClient::configured()?,
        })
    }

    /// The API is the only persistence backend: build the client, and
    /// if that fails log loudly and return a repository whose every
    /// operation fails with the construction error.
    pub fn configured() -> Self {
        match Self::new() {
            Ok(repository) => repository,
            Err(error) => {
                crate::log::log(
                    "phone",
                    "ERROR",
                    &format!(
                        "forge-webapi client unavailable, phone persistence disabled: {error}"
                    ),
                );
                Self::unavailable(error)
            }
        }
    }

    /// A repository that fails every operation with `error`: used when
    /// the API client could not be built.
    pub fn unavailable(error: String) -> Self {
        Self {
            client: ApiClient::unavailable(error),
        }
    }

    fn path(uid: &str) -> String {
        format!("/players/{}/phone", encode_segment(uid))
    }

    /// GET the whole API payload, `None` on 404.
    fn fetch_payload(&self, uid: &str) -> Result<Option<PhonePayload>, String> {
        let path = Self::path(uid);
        let (status, body) = self.client.get(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return Ok(None);
        }
        let body = require_success("GET", &path, status, body)?;
        Ok(Some(phone_from_api_record(body)?))
    }

    /// POST the API's init for `uid`. The API seeds the contacts with
    /// the player themself and the Field Commander.
    fn init_api_phone(&self, uid: &str) -> Result<(), String> {
        let path = Self::path(uid);
        let (status, body) = self.client.post(&path, None)?;
        require_success("POST", &path, status, body)?;
        Ok(())
    }

    /// POST a message/email to the sender's phone. The API only
    /// auto-creates the receiver's phone, so a sender without one (a
    /// Field Commander send) is initialized and the POST retried once.
    fn post_from_sender(&self, from: &str, path: &str, body: JsonValue) -> Result<(), String> {
        let (status, response) = self.client.post(path, Some(body.clone()))?;
        if status == reqwest::StatusCode::NOT_FOUND {
            self.init_api_phone(from)?;
            let (status, response) = self.client.post(path, Some(body))?;
            require_success("POST", path, status, response)?;
            return Ok(());
        }
        require_success("POST", path, status, response)?;
        Ok(())
    }

    fn parse_added(body: JsonValue) -> Result<bool, String> {
        body.get("added")
            .and_then(|value| value.as_bool())
            .ok_or_else(|| "forge-webapi contact decode failed".to_string())
    }

    fn parse_removed(body: JsonValue) -> Result<bool, String> {
        body.get("removed")
            .and_then(|value| value.as_bool())
            .ok_or_else(|| "forge-webapi contact decode failed".to_string())
    }

    fn parse_messages(body: JsonValue) -> Result<Vec<PhoneMessage>, String> {
        let messages = body.get("messages").cloned().unwrap_or(JsonValue::Null);
        serde_json::from_value(messages)
            .map_err(|error| format!("forge-webapi phone messages decode failed: {error}"))
    }

    fn parse_emails(body: JsonValue) -> Result<Vec<PhoneEmail>, String> {
        let emails = body.get("emails").cloned().unwrap_or(JsonValue::Null);
        serde_json::from_value(emails)
            .map_err(|error| format!("forge-webapi phone emails decode failed: {error}"))
    }
}

impl PhoneRepository for ApiPhoneRepository {
    fn init(&self, uid: &str) -> Result<(), String> {
        if self.fetch_payload(uid)?.is_some() {
            return Ok(());
        }
        self.init_api_phone(uid)
    }

    fn add_contact(&self, uid: &str, contact_uid: &str) -> Result<bool, String> {
        let path = format!("{}/contacts", Self::path(uid));
        let body = serde_json::json!({ "contactUid": contact_uid });
        let (status, response) = self.client.post(&path, Some(body))?;
        let response = require_success("POST", &path, status, response)?;
        Self::parse_added(response)
    }

    fn remove_contact(&self, uid: &str, contact_uid: &str) -> Result<bool, String> {
        let path = format!(
            "{}/contacts/{}",
            Self::path(uid),
            encode_segment(contact_uid)
        );
        let (status, body) = self.client.delete(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return Ok(false);
        }
        let body = require_success("DELETE", &path, status, body)?;
        Self::parse_removed(body)
    }

    fn list_contacts(&self, uid: &str) -> Result<Vec<String>, String> {
        Ok(self
            .fetch_payload(uid)?
            .map(|payload| payload.contacts)
            .unwrap_or_default())
    }

    fn remove_phone(&self, uid: &str) -> Result<(), String> {
        let path = Self::path(uid);
        let (status, body) = self.client.delete(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return Ok(());
        }
        require_success("DELETE", &path, status, body)?;
        Ok(())
    }

    fn append_message(&self, uid: &str, message: PhoneMessage) -> Result<(), String> {
        let from = if message.from.trim().is_empty() {
            uid
        } else {
            message.from.as_str()
        };
        let path = format!("{}/messages", Self::path(from));
        let mut body = serde_json::json!({
            "to": message.to,
            "message": message.message,
            "timestamp": message.timestamp,
        });
        if !message.id.trim().is_empty() {
            body["id"] = serde_json::json!(message.id);
        }
        self.post_from_sender(from, &path, body)
    }

    fn list_messages(&self, uid: &str) -> Result<Vec<PhoneMessage>, String> {
        let path = format!("{}/messages", Self::path(uid));
        let (status, body) = self.client.get(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return Ok(Vec::new());
        }
        let body = require_success("GET", &path, status, body)?;
        Self::parse_messages(body)
    }

    fn mark_message_read(&self, uid: &str, message_id: &str) -> Result<bool, String> {
        let path = format!(
            "{}/messages/{}/read",
            Self::path(uid),
            encode_segment(message_id)
        );
        let (status, body) = self.client.post(&path, None)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return Ok(false);
        }
        require_success("POST", &path, status, body)?;
        Ok(true)
    }

    fn delete_message(&self, uid: &str, message_id: &str) -> Result<bool, String> {
        let path = format!(
            "{}/messages/{}",
            Self::path(uid),
            encode_segment(message_id)
        );
        let (status, body) = self.client.delete(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return Ok(false);
        }
        require_success("DELETE", &path, status, body)?;
        Ok(true)
    }

    fn append_email(&self, uid: &str, email: PhoneEmail) -> Result<(), String> {
        let from = if email.from.trim().is_empty() {
            uid
        } else {
            email.from.as_str()
        };
        let path = format!("{}/emails", Self::path(from));
        let mut body = serde_json::json!({
            "to": email.to,
            "subject": email.subject,
            "body": email.body,
            "timestamp": email.timestamp,
        });
        if !email.id.trim().is_empty() {
            body["id"] = serde_json::json!(email.id);
        }
        self.post_from_sender(from, &path, body)
    }

    fn list_emails(&self, uid: &str) -> Result<Vec<PhoneEmail>, String> {
        let path = format!("{}/emails", Self::path(uid));
        let (status, body) = self.client.get(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return Ok(Vec::new());
        }
        let body = require_success("GET", &path, status, body)?;
        Self::parse_emails(body)
    }

    fn mark_email_read(&self, uid: &str, email_id: &str) -> Result<bool, String> {
        let path = format!(
            "{}/emails/{}/read",
            Self::path(uid),
            encode_segment(email_id)
        );
        let (status, body) = self.client.post(&path, None)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return Ok(false);
        }
        require_success("POST", &path, status, body)?;
        Ok(true)
    }

    fn delete_email(&self, uid: &str, email_id: &str) -> Result<bool, String> {
        let path = format!("{}/emails/{}", Self::path(uid), encode_segment(email_id));
        let (status, body) = self.client.delete(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return Ok(false);
        }
        require_success("DELETE", &path, status, body)?;
        Ok(true)
    }

    fn next_sequence(&self) -> Result<u64, String> {
        // Same shape/uniqueness as the API's own id generation: the
        // current time in nanoseconds.
        Ok(std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|duration| duration.as_nanos() as u64)
            .unwrap_or(0))
    }
}
