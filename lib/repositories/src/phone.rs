use forge_models::{PhoneEmail, PhoneMessage};
use std::collections::{HashMap, HashSet};
use std::sync::{Arc, RwLock};

pub trait PhoneRepository: Send + Sync {
    fn init(&self, uid: &str) -> Result<(), String>;
    fn add_contact(&self, uid: &str, contact_uid: &str) -> Result<bool, String>;
    fn remove_contact(&self, uid: &str, contact_uid: &str) -> Result<bool, String>;
    fn list_contacts(&self, uid: &str) -> Result<Vec<String>, String>;
    fn remove_phone(&self, uid: &str) -> Result<(), String>;

    fn append_message(&self, uid: &str, message: PhoneMessage) -> Result<(), String>;
    fn list_messages(&self, uid: &str) -> Result<Vec<PhoneMessage>, String>;
    fn mark_message_read(&self, uid: &str, message_id: &str) -> Result<bool, String>;
    fn delete_message(&self, uid: &str, message_id: &str) -> Result<bool, String>;

    fn append_email(&self, uid: &str, email: PhoneEmail) -> Result<(), String>;
    fn list_emails(&self, uid: &str) -> Result<Vec<PhoneEmail>, String>;
    fn mark_email_read(&self, uid: &str, email_id: &str) -> Result<bool, String>;
    fn delete_email(&self, uid: &str, email_id: &str) -> Result<bool, String>;

    fn next_sequence(&self) -> Result<u64, String>;
}

#[derive(Debug, Default)]
struct PhoneState {
    contacts: HashMap<String, HashSet<String>>,
    messages: HashMap<String, Vec<PhoneMessage>>,
    emails: HashMap<String, Vec<PhoneEmail>>,
    sequence: u64,
}

#[derive(Clone, Debug, Default)]
pub struct InMemoryPhoneRepository {
    state: Arc<RwLock<PhoneState>>,
}

impl InMemoryPhoneRepository {
    pub fn new() -> Self {
        Self::default()
    }
}

impl PhoneRepository for InMemoryPhoneRepository {
    fn init(&self, uid: &str) -> Result<(), String> {
        let mut state = self
            .state
            .write()
            .map_err(|_| "Phone state lock poisoned.".to_string())?;
        state.contacts.entry(uid.to_string()).or_default();
        state.messages.entry(uid.to_string()).or_default();
        state.emails.entry(uid.to_string()).or_default();
        Ok(())
    }

    fn add_contact(&self, uid: &str, contact_uid: &str) -> Result<bool, String> {
        let mut state = self
            .state
            .write()
            .map_err(|_| "Phone contact state lock poisoned.".to_string())?;
        Ok(state
            .contacts
            .entry(uid.to_string())
            .or_default()
            .insert(contact_uid.to_string()))
    }

    fn remove_contact(&self, uid: &str, contact_uid: &str) -> Result<bool, String> {
        let mut state = self
            .state
            .write()
            .map_err(|_| "Phone contact state lock poisoned.".to_string())?;
        Ok(state
            .contacts
            .entry(uid.to_string())
            .or_default()
            .remove(contact_uid))
    }

    fn list_contacts(&self, uid: &str) -> Result<Vec<String>, String> {
        let mut contacts = self
            .state
            .read()
            .map_err(|_| "Phone contact state lock poisoned.".to_string())?
            .contacts
            .get(uid)
            .map(|contacts| contacts.iter().cloned().collect::<Vec<_>>())
            .unwrap_or_default();
        contacts.sort();
        Ok(contacts)
    }

    fn remove_phone(&self, uid: &str) -> Result<(), String> {
        let mut state = self
            .state
            .write()
            .map_err(|_| "Phone state lock poisoned.".to_string())?;
        state.contacts.remove(uid);
        state.messages.remove(uid);
        state.emails.remove(uid);
        Ok(())
    }

    fn append_message(&self, uid: &str, message: PhoneMessage) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "Phone message state lock poisoned.".to_string())?
            .messages
            .entry(uid.to_string())
            .or_default()
            .push(message);
        Ok(())
    }

    fn list_messages(&self, uid: &str) -> Result<Vec<PhoneMessage>, String> {
        let mut messages = self
            .state
            .read()
            .map_err(|_| "Phone message state lock poisoned.".to_string())?
            .messages
            .get(uid)
            .cloned()
            .unwrap_or_default();
        messages.sort_by(|left, right| {
            left.timestamp
                .partial_cmp(&right.timestamp)
                .unwrap_or(std::cmp::Ordering::Equal)
        });
        Ok(messages)
    }

    fn mark_message_read(&self, uid: &str, message_id: &str) -> Result<bool, String> {
        let mut state = self
            .state
            .write()
            .map_err(|_| "Phone message state lock poisoned.".to_string())?;
        let Some(messages) = state.messages.get_mut(uid) else {
            return Ok(false);
        };
        let mut found = false;
        for message in messages {
            if message.id == message_id {
                message.read = true;
                found = true;
            }
        }
        Ok(found)
    }

    fn delete_message(&self, uid: &str, message_id: &str) -> Result<bool, String> {
        let mut state = self
            .state
            .write()
            .map_err(|_| "Phone message state lock poisoned.".to_string())?;
        let Some(messages) = state.messages.get_mut(uid) else {
            return Ok(false);
        };
        let original_len = messages.len();
        messages.retain(|message| message.id != message_id);
        Ok(messages.len() != original_len)
    }

    fn append_email(&self, uid: &str, email: PhoneEmail) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "Phone email state lock poisoned.".to_string())?
            .emails
            .entry(uid.to_string())
            .or_default()
            .push(email);
        Ok(())
    }

    fn list_emails(&self, uid: &str) -> Result<Vec<PhoneEmail>, String> {
        let mut emails = self
            .state
            .read()
            .map_err(|_| "Phone email state lock poisoned.".to_string())?
            .emails
            .get(uid)
            .cloned()
            .unwrap_or_default();
        emails.sort_by(|left, right| {
            right
                .timestamp
                .partial_cmp(&left.timestamp)
                .unwrap_or(std::cmp::Ordering::Equal)
        });
        Ok(emails)
    }

    fn mark_email_read(&self, uid: &str, email_id: &str) -> Result<bool, String> {
        let mut state = self
            .state
            .write()
            .map_err(|_| "Phone email state lock poisoned.".to_string())?;
        let Some(emails) = state.emails.get_mut(uid) else {
            return Ok(false);
        };
        let mut found = false;
        for email in emails {
            if email.id == email_id {
                email.read = true;
                found = true;
            }
        }
        Ok(found)
    }

    fn delete_email(&self, uid: &str, email_id: &str) -> Result<bool, String> {
        let mut state = self
            .state
            .write()
            .map_err(|_| "Phone email state lock poisoned.".to_string())?;
        let Some(emails) = state.emails.get_mut(uid) else {
            return Ok(false);
        };
        let original_len = emails.len();
        emails.retain(|email| email.id != email_id);
        Ok(emails.len() != original_len)
    }

    fn next_sequence(&self) -> Result<u64, String> {
        let mut state = self
            .state
            .write()
            .map_err(|_| "Phone sequence lock poisoned.".to_string())?;
        state.sequence += 1;
        Ok(state.sequence)
    }
}
