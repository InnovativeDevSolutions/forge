use super::common::*;
use super::*;
use crate::api::{
    ApiClient, encode_segment, phone_from_api_record, phone_to_api_body, require_success,
};
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
/// is then a no-op. The sender's copy is marked read by the API,
/// matching the legacy per-side index. `init` migrates a legacy phone
/// on first use; the service's two seed `add_contact` calls after it
/// are idempotent.
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
    /// operation fails with the construction error. There is no
    /// fallback to SurrealDB.
    pub fn configured() -> Self {
        match Self::new() {
            Ok(repository) => repository,
            Err(error) => {
                crate::log::log(
                    "phone",
                    "ERROR",
                    &format!(
                        "forge-webapi client unavailable, phone persistence disabled (no SurrealDB fallback): {error}"
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

    fn put_payload(&self, uid: &str, payload: &PhonePayload) -> Result<(), String> {
        let path = Self::path(uid);
        let body = phone_to_api_body(uid, payload)?;
        let (status, response) = self.client.put(&path, Some(body))?;
        require_success("PUT", &path, status, response)?;
        Ok(())
    }

    /// GET the whole API payload, `None` on 404. Does not migrate.
    fn fetch_payload(&self, uid: &str) -> Result<Option<PhonePayload>, String> {
        let path = Self::path(uid);
        let (status, body) = self.client.get(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return Ok(None);
        }
        let body = require_success("GET", &path, status, body)?;
        Ok(Some(phone_from_api_record(body)?))
    }

    /// Move a legacy phone into the API: contacts, messages (with
    /// their ids and read flags) and emails are read whole and PUT as
    /// one payload. Returns `true` when a legacy phone existed and was
    /// moved. Any legacy-read error fails open (warn, `false` — the
    /// legacy rows are left alone, and the caller proceeds as if no
    /// legacy phone existed); an API-write error propagates. The
    /// legacy rows are deleted best-effort after a successful PUT via
    /// `LegacyPhoneRepository::remove_phone`, which only removes this
    /// uid's index rows plus orphan cleanup, so the other side's
    /// copies of shared messages survive.
    fn migrate(&self, uid: &str) -> Result<bool, String> {
        let legacy = LegacyPhoneRepository;
        let legacy_exists = match surreal_select::<PhoneUserRecord>("phone_user", uid, "phone user")
        {
            Ok(record) => record.is_some(),
            Err(error) => {
                crate::log::log(
                    "phone",
                    "WARN",
                    &format!(
                        "forge-webapi phone migration: legacy phone read failed for {uid}, proceeding without it: {error}"
                    ),
                );
                return Ok(false);
            }
        };
        if !legacy_exists {
            return Ok(false);
        }
        let contacts = match legacy.list_contacts(uid) {
            Ok(contacts) => contacts,
            Err(error) => {
                crate::log::log(
                    "phone",
                    "WARN",
                    &format!(
                        "forge-webapi phone migration: legacy contacts read failed for {uid}, proceeding without migration: {error}"
                    ),
                );
                return Ok(false);
            }
        };
        let messages = match legacy.list_messages(uid) {
            Ok(messages) => messages,
            Err(error) => {
                crate::log::log(
                    "phone",
                    "WARN",
                    &format!(
                        "forge-webapi phone migration: legacy messages read failed for {uid}, proceeding without migration: {error}"
                    ),
                );
                return Ok(false);
            }
        };
        let emails = match legacy.list_emails(uid) {
            Ok(emails) => emails,
            Err(error) => {
                crate::log::log(
                    "phone",
                    "WARN",
                    &format!(
                        "forge-webapi phone migration: legacy emails read failed for {uid}, proceeding without migration: {error}"
                    ),
                );
                return Ok(false);
            }
        };
        let payload = PhonePayload {
            contacts,
            messages,
            emails,
        };
        self.put_payload(uid, &payload)?;
        if let Err(error) = legacy.remove_phone(uid) {
            crate::log::log(
                "phone",
                "WARN",
                &format!(
                    "forge-webapi phone migration: legacy phone delete failed for {uid} after migration: {error}"
                ),
            );
        }
        Ok(true)
    }

    /// POST the API's init for `uid`. The API seeds the contacts with
    /// the player themself and the Field Commander.
    fn init_api_phone(&self, uid: &str) -> Result<(), String> {
        let path = Self::path(uid);
        let (status, body) = self.client.post(&path, None)?;
        require_success("POST", &path, status, body)?;
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

    /// The message/email list for `uid`, migrating a legacy phone on
    /// 404. Used by `list_messages` / `list_emails`.
    fn list_via_payload<F, T>(&self, uid: &str, pick: F) -> Result<T, String>
    where
        F: Fn(PhonePayload) -> T,
        T: Default,
    {
        match self.fetch_payload(uid)? {
            Some(payload) => Ok(pick(payload)),
            None => {
                if self.migrate(uid)? {
                    return Ok(self.fetch_payload(uid)?.map(pick).unwrap_or_default());
                }
                Ok(T::default())
            }
        }
    }
}

impl PhoneRepository for ApiPhoneRepository {
    fn init(&self, uid: &str) -> Result<(), String> {
        if self.fetch_payload(uid)?.is_some() {
            return Ok(());
        }
        // No API phone: migrate a legacy one, else let the API seed a
        // new phone.
        if self.migrate(uid)? {
            return Ok(());
        }
        self.init_api_phone(uid)
    }

    fn add_contact(&self, uid: &str, contact_uid: &str) -> Result<bool, String> {
        let path = format!("{}/contacts", Self::path(uid));
        let body = serde_json::json!({ "contactUid": contact_uid });
        let (status, response) = self.client.post(&path, Some(body.clone()))?;
        if status == reqwest::StatusCode::NOT_FOUND && self.migrate(uid)? {
            let (status, response) = self.client.post(&path, Some(body))?;
            let response = require_success("POST", &path, status, response)?;
            return Self::parse_added(response);
        }
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
            if self.migrate(uid)? {
                let (status, body) = self.client.delete(&path)?;
                if status == reqwest::StatusCode::NOT_FOUND {
                    return Ok(false);
                }
                let body = require_success("DELETE", &path, status, body)?;
                return Self::parse_removed(body);
            }
            return Ok(false);
        }
        let body = require_success("DELETE", &path, status, body)?;
        Self::parse_removed(body)
    }

    fn list_contacts(&self, uid: &str) -> Result<Vec<String>, String> {
        self.list_via_payload(uid, |payload| payload.contacts)
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
        let (status, response) = self.client.post(&path, Some(body.clone()))?;
        if status == reqwest::StatusCode::NOT_FOUND {
            if self.migrate(from)? {
                let (status, response) = self.client.post(&path, Some(body))?;
                require_success("POST", &path, status, response)?;
                return Ok(());
            }
            // The legacy repository auto-creates the sender's phone on
            // append (a Field Commander send has no phone yet); the
            // API only auto-creates the receiver's. Init the sender,
            // then retry once.
            self.init_api_phone(from)?;
            let (status, response) = self.client.post(&path, Some(body))?;
            require_success("POST", &path, status, response)?;
            return Ok(());
        }
        require_success("POST", &path, status, response)?;
        Ok(())
    }

    fn list_messages(&self, uid: &str) -> Result<Vec<PhoneMessage>, String> {
        let path = format!("{}/messages", Self::path(uid));
        let (status, body) = self.client.get(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            if self.migrate(uid)? {
                let (status, body) = self.client.get(&path)?;
                let body = require_success("GET", &path, status, body)?;
                return Self::parse_messages(body);
            }
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
        let (status, response) = self.client.post(&path, Some(body.clone()))?;
        if status == reqwest::StatusCode::NOT_FOUND {
            if self.migrate(from)? {
                let (status, response) = self.client.post(&path, Some(body))?;
                require_success("POST", &path, status, response)?;
                return Ok(());
            }
            // Same sender auto-create as `append_message`: the legacy
            // repository creates the sender's phone on append.
            self.init_api_phone(from)?;
            let (status, response) = self.client.post(&path, Some(body))?;
            require_success("POST", &path, status, response)?;
            return Ok(());
        }
        require_success("POST", &path, status, response)?;
        Ok(())
    }

    fn list_emails(&self, uid: &str) -> Result<Vec<PhoneEmail>, String> {
        let path = format!("{}/emails", Self::path(uid));
        let (status, body) = self.client.get(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            if self.migrate(uid)? {
                let (status, body) = self.client.get(&path)?;
                let body = require_success("GET", &path, status, body)?;
                return Self::parse_emails(body);
            }
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

#[derive(Debug, Clone, Serialize, Deserialize)]
struct PhoneUserRecord {
    uid: String,
}

impl PhoneUserRecord {
    fn new(uid: &str) -> Self {
        Self {
            uid: uid.to_string(),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct PhoneContactRecord {
    uid: String,
    contact_uid: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct PhoneMessageIndexRecord {
    uid: String,
    message_id: String,
    is_read: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct PhoneEmailIndexRecord {
    uid: String,
    email_id: String,
    is_read: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct PhoneMessageRecord {
    message_id: String,
    from_uid: String,
    to_uid: String,
    message: String,
    timestamp: f64,
}

impl PhoneMessageRecord {
    fn into_message(self, read: bool) -> PhoneMessage {
        PhoneMessage {
            id: self.message_id,
            from: self.from_uid,
            to: self.to_uid,
            message: self.message,
            timestamp: self.timestamp,
            read,
        }
    }
}

impl From<&PhoneMessage> for PhoneMessageRecord {
    fn from(message: &PhoneMessage) -> Self {
        Self {
            message_id: message.id.clone(),
            from_uid: message.from.clone(),
            to_uid: message.to.clone(),
            message: message.message.clone(),
            timestamp: message.timestamp,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct PhoneEmailRecord {
    email_id: String,
    from_uid: String,
    to_uid: String,
    subject: String,
    body: String,
    timestamp: f64,
}

impl PhoneEmailRecord {
    fn into_email(self, read: bool) -> PhoneEmail {
        PhoneEmail {
            id: self.email_id,
            from: self.from_uid,
            to: self.to_uid,
            subject: self.subject,
            body: self.body,
            timestamp: self.timestamp,
            read,
        }
    }
}

impl From<&PhoneEmail> for PhoneEmailRecord {
    fn from(email: &PhoneEmail) -> Self {
        Self {
            email_id: email.id.clone(),
            from_uid: email.from.clone(),
            to_uid: email.to.clone(),
            subject: email.subject.clone(),
            body: email.body.clone(),
            timestamp: email.timestamp,
        }
    }
}

#[derive(Debug, Default, Clone, Serialize, Deserialize)]
struct PhoneSequenceRecord {
    #[serde(default)]
    sequence_id: String,
    #[serde(default)]
    value: u64,
}

/// Legacy phone rows in SurrealDB (`phone_user`, `phone_contact`,
/// `phone_message`, `phone_message_index`, `phone_email`,
/// `phone_email_index`, `phone_sequence`).
///
/// Migration-only: read once by [`ApiPhoneRepository::migrate`] so a
/// legacy phone can be moved into the API, then deleted. Never used
/// as a live backend — there is no fallback.
pub struct LegacyPhoneRepository;

impl LegacyPhoneRepository {
    fn save_user(&self, uid: &str) -> Result<(), String> {
        let record = PhoneUserRecord::new(uid);
        surreal_upsert("phone_user", uid, "phone user", &record)
    }

    fn message_is_referenced(&self, message_id: &str) -> Result<bool, String> {
        Ok(!surreal_select_by_field::<PhoneMessageIndexRecord>(
            "phone_message_index",
            "phone message indexes",
            "message_id",
            message_id,
        )?
        .is_empty())
    }

    fn email_is_referenced(&self, email_id: &str) -> Result<bool, String> {
        Ok(!surreal_select_by_field::<PhoneEmailIndexRecord>(
            "phone_email_index",
            "phone email indexes",
            "email_id",
            email_id,
        )?
        .is_empty())
    }

    fn cleanup_orphaned_records(&self) -> Result<(), String> {
        let referenced_messages = surreal_select_all::<PhoneMessageIndexRecord>(
            "phone_message_index",
            "phone message indexes",
        )?
        .into_iter()
        .map(|record| record.message_id)
        .collect::<HashSet<_>>();
        let referenced_emails = surreal_select_all::<PhoneEmailIndexRecord>(
            "phone_email_index",
            "phone email indexes",
        )?
        .into_iter()
        .map(|record| record.email_id)
        .collect::<HashSet<_>>();

        for record in surreal_select_all::<PhoneMessageRecord>("phone_message", "phone messages")? {
            let message_id = record.message_id.trim();
            if !message_id.is_empty() && !referenced_messages.contains(message_id) {
                surreal_delete::<PhoneMessageRecord>("phone_message", message_id, "phone message")?;
            }
        }

        for record in surreal_select_all::<PhoneEmailRecord>("phone_email", "phone emails")? {
            let email_id = record.email_id.trim();
            if !email_id.is_empty() && !referenced_emails.contains(email_id) {
                surreal_delete::<PhoneEmailRecord>("phone_email", email_id, "phone email")?;
            }
        }

        Ok(())
    }

    fn contact_id(uid: &str, contact_uid: &str) -> String {
        format!("{}:{}", uid, contact_uid)
    }

    fn message_index_id(uid: &str, message_id: &str) -> String {
        format!("{}:{}", uid, message_id)
    }

    fn email_index_id(uid: &str, email_id: &str) -> String {
        format!("{}:{}", uid, email_id)
    }
}

impl PhoneRepository for LegacyPhoneRepository {
    fn init(&self, uid: &str) -> Result<(), String> {
        if surreal_select::<PhoneUserRecord>("phone_user", uid, "phone user")?.is_none() {
            self.save_user(uid)?;
        }
        self.cleanup_orphaned_records()?;
        Ok(())
    }

    fn add_contact(&self, uid: &str, contact_uid: &str) -> Result<bool, String> {
        self.save_user(uid)?;
        let record = PhoneContactRecord {
            uid: uid.to_string(),
            contact_uid: contact_uid.to_string(),
        };
        surreal_upsert(
            "phone_contact",
            &Self::contact_id(uid, contact_uid),
            "phone contact",
            &record,
        )?;
        Ok(true)
    }

    fn remove_contact(&self, uid: &str, contact_uid: &str) -> Result<bool, String> {
        let id = Self::contact_id(uid, contact_uid);
        let exists =
            surreal_select::<PhoneContactRecord>("phone_contact", &id, "phone contact")?.is_some();
        if !exists {
            return Ok(false);
        }

        surreal_delete::<PhoneContactRecord>("phone_contact", &id, "phone contact")?;
        Ok(true)
    }

    fn list_contacts(&self, uid: &str) -> Result<Vec<String>, String> {
        let mut contacts =
            surreal_select_by_uid::<PhoneContactRecord>("phone_contact", "phone contacts", uid)?
                .into_iter()
                .map(|record| record.contact_uid)
                .collect::<Vec<_>>();
        contacts.sort();
        contacts.dedup();
        Ok(contacts)
    }

    fn remove_phone(&self, uid: &str) -> Result<(), String> {
        surreal_delete_by_uid("phone_contact", "phone contacts", uid)?;
        surreal_delete_by_uid("phone_message_index", "phone message indexes", uid)?;
        surreal_delete_by_uid("phone_email_index", "phone email indexes", uid)?;
        surreal_delete::<PhoneUserRecord>("phone_user", uid, "phone user")?;
        self.cleanup_orphaned_records()
    }

    fn append_message(&self, uid: &str, message: PhoneMessage) -> Result<(), String> {
        self.save_user(uid)?;

        let record = PhoneMessageRecord::from(&message);
        surreal_upsert("phone_message", &message.id, "phone message", &record)?;
        let index = PhoneMessageIndexRecord {
            uid: uid.to_string(),
            message_id: message.id.clone(),
            is_read: message.from == uid,
        };
        surreal_upsert(
            "phone_message_index",
            &Self::message_index_id(uid, &message.id),
            "phone message index",
            &index,
        )
    }

    fn list_messages(&self, uid: &str) -> Result<Vec<PhoneMessage>, String> {
        let indexes = surreal_select_by_uid::<PhoneMessageIndexRecord>(
            "phone_message_index",
            "phone message indexes",
            uid,
        )?;
        let mut messages = Vec::with_capacity(indexes.len());

        for index in indexes {
            if index.message_id.trim().is_empty() {
                continue;
            }

            if let Some(record) = surreal_select::<PhoneMessageRecord>(
                "phone_message",
                &index.message_id,
                "phone message",
            )? {
                messages.push(record.into_message(index.is_read));
            }
        }

        messages.sort_by(|left, right| {
            left.timestamp
                .partial_cmp(&right.timestamp)
                .unwrap_or(std::cmp::Ordering::Equal)
        });
        Ok(messages)
    }

    fn mark_message_read(&self, uid: &str, message_id: &str) -> Result<bool, String> {
        let id = Self::message_index_id(uid, message_id);
        let Some(mut index) = surreal_select::<PhoneMessageIndexRecord>(
            "phone_message_index",
            &id,
            "phone message index",
        )?
        else {
            return Ok(false);
        };

        index.is_read = true;
        surreal_upsert("phone_message_index", &id, "phone message index", &index)?;
        Ok(true)
    }

    fn delete_message(&self, uid: &str, message_id: &str) -> Result<bool, String> {
        let id = Self::message_index_id(uid, message_id);
        let exists = surreal_select::<PhoneMessageIndexRecord>(
            "phone_message_index",
            &id,
            "phone message index",
        )?
        .is_some();
        if !exists {
            return Ok(false);
        }

        surreal_delete::<PhoneMessageIndexRecord>(
            "phone_message_index",
            &id,
            "phone message index",
        )?;
        if !self.message_is_referenced(message_id)? {
            surreal_delete::<PhoneMessageRecord>("phone_message", message_id, "phone message")?;
        }
        Ok(true)
    }

    fn append_email(&self, uid: &str, email: PhoneEmail) -> Result<(), String> {
        self.save_user(uid)?;

        let record = PhoneEmailRecord::from(&email);
        surreal_upsert("phone_email", &email.id, "phone email", &record)?;
        let index = PhoneEmailIndexRecord {
            uid: uid.to_string(),
            email_id: email.id.clone(),
            is_read: false,
        };
        surreal_upsert(
            "phone_email_index",
            &Self::email_index_id(uid, &email.id),
            "phone email index",
            &index,
        )
    }

    fn list_emails(&self, uid: &str) -> Result<Vec<PhoneEmail>, String> {
        let indexes = surreal_select_by_uid::<PhoneEmailIndexRecord>(
            "phone_email_index",
            "phone email indexes",
            uid,
        )?;
        let mut emails = Vec::with_capacity(indexes.len());

        for index in indexes {
            if index.email_id.trim().is_empty() {
                continue;
            }

            if let Some(record) =
                surreal_select::<PhoneEmailRecord>("phone_email", &index.email_id, "phone email")?
            {
                emails.push(record.into_email(index.is_read));
            }
        }

        emails.sort_by(|left, right| {
            right
                .timestamp
                .partial_cmp(&left.timestamp)
                .unwrap_or(std::cmp::Ordering::Equal)
        });
        Ok(emails)
    }

    fn mark_email_read(&self, uid: &str, email_id: &str) -> Result<bool, String> {
        let id = Self::email_index_id(uid, email_id);
        let Some(mut index) =
            surreal_select::<PhoneEmailIndexRecord>("phone_email_index", &id, "phone email index")?
        else {
            return Ok(false);
        };

        index.is_read = true;
        surreal_upsert("phone_email_index", &id, "phone email index", &index)?;
        Ok(true)
    }

    fn delete_email(&self, uid: &str, email_id: &str) -> Result<bool, String> {
        let id = Self::email_index_id(uid, email_id);
        let exists =
            surreal_select::<PhoneEmailIndexRecord>("phone_email_index", &id, "phone email index")?
                .is_some();
        if !exists {
            return Ok(false);
        }

        surreal_delete::<PhoneEmailIndexRecord>("phone_email_index", &id, "phone email index")?;
        if !self.email_is_referenced(email_id)? {
            surreal_delete::<PhoneEmailRecord>("phone_email", email_id, "phone email")?;
        }
        Ok(true)
    }

    fn next_sequence(&self) -> Result<u64, String> {
        let mut record =
            surreal_select::<PhoneSequenceRecord>("phone_sequence", "global", "phone sequence")?
                .unwrap_or_default();
        record.sequence_id = "global".to_string();
        record.value = record
            .value
            .checked_add(1)
            .ok_or_else(|| "Phone sequence overflowed.".to_string())?;
        surreal_upsert("phone_sequence", "global", "phone sequence", &record)?;
        Ok(record.value)
    }
}
