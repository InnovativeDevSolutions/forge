use super::common::*;
use super::*;

pub enum PhoneStorageRepository {
    Surreal(SurrealPhoneRepository),
}

impl PhoneStorageRepository {
    pub fn configured() -> Self {
        Self::Surreal(SurrealPhoneRepository)
    }
}

impl PhoneRepository for PhoneStorageRepository {
    fn init(&self, uid: &str) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.init(uid),
        }
    }

    fn add_contact(&self, uid: &str, contact_uid: &str) -> Result<bool, String> {
        match self {
            Self::Surreal(repository) => repository.add_contact(uid, contact_uid),
        }
    }

    fn remove_contact(&self, uid: &str, contact_uid: &str) -> Result<bool, String> {
        match self {
            Self::Surreal(repository) => repository.remove_contact(uid, contact_uid),
        }
    }

    fn list_contacts(&self, uid: &str) -> Result<Vec<String>, String> {
        match self {
            Self::Surreal(repository) => repository.list_contacts(uid),
        }
    }

    fn remove_phone(&self, uid: &str) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.remove_phone(uid),
        }
    }

    fn append_message(&self, uid: &str, message: PhoneMessage) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.append_message(uid, message),
        }
    }

    fn list_messages(&self, uid: &str) -> Result<Vec<PhoneMessage>, String> {
        match self {
            Self::Surreal(repository) => repository.list_messages(uid),
        }
    }

    fn mark_message_read(&self, uid: &str, message_id: &str) -> Result<bool, String> {
        match self {
            Self::Surreal(repository) => repository.mark_message_read(uid, message_id),
        }
    }

    fn delete_message(&self, uid: &str, message_id: &str) -> Result<bool, String> {
        match self {
            Self::Surreal(repository) => repository.delete_message(uid, message_id),
        }
    }

    fn append_email(&self, uid: &str, email: PhoneEmail) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.append_email(uid, email),
        }
    }

    fn list_emails(&self, uid: &str) -> Result<Vec<PhoneEmail>, String> {
        match self {
            Self::Surreal(repository) => repository.list_emails(uid),
        }
    }

    fn mark_email_read(&self, uid: &str, email_id: &str) -> Result<bool, String> {
        match self {
            Self::Surreal(repository) => repository.mark_email_read(uid, email_id),
        }
    }

    fn delete_email(&self, uid: &str, email_id: &str) -> Result<bool, String> {
        match self {
            Self::Surreal(repository) => repository.delete_email(uid, email_id),
        }
    }

    fn next_sequence(&self) -> Result<u64, String> {
        match self {
            Self::Surreal(repository) => repository.next_sequence(),
        }
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

pub struct SurrealPhoneRepository;

impl SurrealPhoneRepository {
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

impl PhoneRepository for SurrealPhoneRepository {
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
