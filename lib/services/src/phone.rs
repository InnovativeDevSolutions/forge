use forge_models::{PhoneEmail, PhoneMessage, PhonePayload};
use forge_repositories::PhoneRepository;

const FIELD_COMMANDER_UID: &str = "field_commander";

pub struct PhoneStateService<R: PhoneRepository> {
    repository: R,
}

impl<R: PhoneRepository> PhoneStateService<R> {
    pub fn new(repository: R) -> Self {
        Self { repository }
    }

    pub fn init(&self, uid: String) -> Result<PhonePayload, String> {
        let uid = Self::validate_uid(uid)?;
        self.repository.init(&uid)?;
        self.repository.add_contact(&uid, &uid)?;
        self.repository.add_contact(&uid, FIELD_COMMANDER_UID)?;
        self.payload_for(&uid)
    }

    pub fn add_contact(&self, uid: String, contact_uid: String) -> Result<bool, String> {
        let uid = Self::validate_uid(uid)?;
        let contact_uid = Self::validate_uid(contact_uid)?;
        self.repository.add_contact(&uid, &contact_uid)
    }

    pub fn remove_contact(&self, uid: String, contact_uid: String) -> Result<bool, String> {
        let uid = Self::validate_uid(uid)?;
        let contact_uid = Self::validate_uid(contact_uid)?;
        self.repository.remove_contact(&uid, &contact_uid)
    }

    pub fn list_contacts(&self, uid: String) -> Result<Vec<String>, String> {
        let uid = Self::validate_uid(uid)?;
        self.repository.list_contacts(&uid)
    }

    pub fn send_message(
        &self,
        from_uid: String,
        to_uid: String,
        message: String,
        timestamp: String,
    ) -> Result<PhoneMessage, String> {
        let from_uid = Self::validate_uid(from_uid)?;
        let to_uid = Self::validate_uid(to_uid)?;
        let message = Self::validate_non_empty(message, "Message body is required.")?;
        Self::validate_send_target(
            &from_uid,
            &to_uid,
            "Field Commander cannot receive player messages.",
        )?;
        let timestamp = Self::parse_timestamp(timestamp);
        let id = format!(
            "phone-message:{}:{}:{}",
            from_uid,
            to_uid,
            self.repository.next_sequence()?
        );
        let record = PhoneMessage {
            id,
            from: from_uid.clone(),
            to: to_uid.clone(),
            message,
            timestamp,
            read: false,
        };

        self.repository.append_message(&from_uid, record.clone())?;
        if to_uid != from_uid {
            self.repository.append_message(&to_uid, record.clone())?;
        }
        Ok(record)
    }

    pub fn list_messages(&self, uid: String) -> Result<Vec<PhoneMessage>, String> {
        let uid = Self::validate_uid(uid)?;
        self.repository.list_messages(&uid)
    }

    pub fn message_thread(
        &self,
        uid: String,
        other_uid: String,
    ) -> Result<Vec<PhoneMessage>, String> {
        let uid = Self::validate_uid(uid)?;
        let other_uid = Self::validate_uid(other_uid)?;
        Ok(self
            .repository
            .list_messages(&uid)?
            .into_iter()
            .filter(|message| {
                (message.from == uid && message.to == other_uid)
                    || (message.from == other_uid && message.to == uid)
            })
            .collect())
    }

    pub fn mark_message_read(&self, uid: String, message_id: String) -> Result<bool, String> {
        let uid = Self::validate_uid(uid)?;
        let message_id = Self::validate_non_empty(message_id, "Message ID is required.")?;
        self.repository.mark_message_read(&uid, &message_id)
    }

    pub fn delete_message(&self, uid: String, message_id: String) -> Result<bool, String> {
        let uid = Self::validate_uid(uid)?;
        let message_id = Self::validate_non_empty(message_id, "Message ID is required.")?;
        self.repository.delete_message(&uid, &message_id)
    }

    pub fn send_email(
        &self,
        from_uid: String,
        to_uid: String,
        subject: String,
        body: String,
        timestamp: String,
    ) -> Result<PhoneEmail, String> {
        let from_uid = Self::validate_uid(from_uid)?;
        let to_uid = Self::validate_uid(to_uid)?;
        let subject = Self::default_subject(subject);
        let body = Self::validate_non_empty(body, "Email body is required.")?;
        Self::validate_send_target(
            &from_uid,
            &to_uid,
            "Field Commander cannot receive player emails.",
        )?;
        let timestamp = Self::parse_timestamp(timestamp);
        let id = format!(
            "phone-email:{}:{}:{}",
            from_uid,
            to_uid,
            self.repository.next_sequence()?
        );
        let record = PhoneEmail {
            id,
            from: from_uid.clone(),
            to: to_uid.clone(),
            subject,
            body,
            timestamp,
            read: false,
        };

        self.repository.append_email(&to_uid, record.clone())?;
        if from_uid != to_uid {
            self.repository.append_email(&from_uid, record.clone())?;
            self.repository.mark_email_read(&from_uid, &record.id)?;
        }
        Ok(record)
    }

    pub fn list_emails(&self, uid: String) -> Result<Vec<PhoneEmail>, String> {
        let uid = Self::validate_uid(uid)?;
        self.repository.list_emails(&uid)
    }

    pub fn mark_email_read(&self, uid: String, email_id: String) -> Result<bool, String> {
        let uid = Self::validate_uid(uid)?;
        let email_id = Self::validate_non_empty(email_id, "Email ID is required.")?;
        self.repository.mark_email_read(&uid, &email_id)
    }

    pub fn delete_email(&self, uid: String, email_id: String) -> Result<bool, String> {
        let uid = Self::validate_uid(uid)?;
        let email_id = Self::validate_non_empty(email_id, "Email ID is required.")?;
        self.repository.delete_email(&uid, &email_id)
    }

    pub fn remove(&self, uid: String) -> Result<(), String> {
        let uid = Self::validate_uid(uid)?;
        self.repository.remove_phone(&uid)
    }

    fn payload_for(&self, uid: &str) -> Result<PhonePayload, String> {
        Ok(PhonePayload {
            contacts: self.repository.list_contacts(uid)?,
            messages: self.repository.list_messages(uid)?,
            emails: self.repository.list_emails(uid)?,
        })
    }

    fn validate_uid(uid: String) -> Result<String, String> {
        let uid = uid.trim().to_string();
        if uid.is_empty() {
            Err("UID is required.".to_string())
        } else {
            Ok(uid)
        }
    }

    fn validate_non_empty(value: String, message: &str) -> Result<String, String> {
        let value = value.trim().to_string();
        if value.is_empty() {
            Err(message.to_string())
        } else {
            Ok(value)
        }
    }

    fn default_subject(value: String) -> String {
        let value = value.trim().to_string();
        if value.is_empty() {
            "No subject".to_string()
        } else {
            value
        }
    }

    fn validate_send_target(from_uid: &str, to_uid: &str, message: &str) -> Result<(), String> {
        if to_uid == FIELD_COMMANDER_UID && from_uid != FIELD_COMMANDER_UID {
            Err(message.to_string())
        } else {
            Ok(())
        }
    }

    fn parse_timestamp(timestamp: String) -> f64 {
        timestamp.trim().parse::<f64>().unwrap_or_default()
    }
}

#[cfg(test)]
mod tests {
    use super::PhoneStateService;
    use forge_repositories::InMemoryPhoneRepository;

    #[test]
    fn send_message_indexes_sender_and_receiver_threads() {
        let service = PhoneStateService::new(InMemoryPhoneRepository::new());

        let message = service
            .send_message(
                "sender".to_string(),
                "receiver".to_string(),
                "Test".to_string(),
                "123".to_string(),
            )
            .expect("message should send");

        assert_eq!(
            service
                .list_messages("sender".to_string())
                .expect("sender messages should load")
                .len(),
            1
        );
        assert_eq!(
            service
                .message_thread("receiver".to_string(), "sender".to_string())
                .expect("thread should load")
                .first()
                .map(|entry| entry.id.clone()),
            Some(message.id)
        );
    }

    #[test]
    fn contact_can_reference_self_for_owner_card() {
        let service = PhoneStateService::new(InMemoryPhoneRepository::new());

        assert!(
            service
                .add_contact("same".to_string(), "same".to_string())
                .expect("self contact should be allowed")
        );
    }

    #[test]
    fn init_seeds_owner_and_field_commander_contacts() {
        let service = PhoneStateService::new(InMemoryPhoneRepository::new());

        let payload = service
            .init("player".to_string())
            .expect("phone should initialize");

        assert!(payload.contacts.iter().any(|uid| uid == "player"));
        assert!(payload.contacts.iter().any(|uid| uid == "field_commander"));
    }

    #[test]
    fn player_cannot_message_field_commander() {
        let service = PhoneStateService::new(InMemoryPhoneRepository::new());

        assert!(
            service
                .send_message(
                    "player".to_string(),
                    "field_commander".to_string(),
                    "Test".to_string(),
                    "123".to_string(),
                )
                .is_err()
        );
    }

    #[test]
    fn field_commander_can_message_player() {
        let service = PhoneStateService::new(InMemoryPhoneRepository::new());

        assert!(
            service
                .send_message(
                    "field_commander".to_string(),
                    "player".to_string(),
                    "Orders".to_string(),
                    "123".to_string(),
                )
                .is_ok()
        );
    }

    #[test]
    fn player_cannot_email_field_commander() {
        let service = PhoneStateService::new(InMemoryPhoneRepository::new());

        assert!(
            service
                .send_email(
                    "player".to_string(),
                    "field_commander".to_string(),
                    "Subject".to_string(),
                    "Body".to_string(),
                    "123".to_string(),
                )
                .is_err()
        );
    }

    #[test]
    fn email_allows_empty_subject() {
        let service = PhoneStateService::new(InMemoryPhoneRepository::new());

        let email = service
            .send_email(
                "player".to_string(),
                "player".to_string(),
                "".to_string(),
                "Body".to_string(),
                "123".to_string(),
            )
            .expect("email should allow empty subject");

        assert_eq!(email.subject, "No subject");
    }

    #[test]
    fn self_message_is_indexed_once() {
        let service = PhoneStateService::new(InMemoryPhoneRepository::new());

        service
            .send_message(
                "same".to_string(),
                "same".to_string(),
                "Test".to_string(),
                "123".to_string(),
            )
            .expect("self message should send");

        assert_eq!(
            service
                .list_messages("same".to_string())
                .expect("self messages should load")
                .len(),
            1
        );
    }

    #[test]
    fn delete_message_removes_only_requesting_users_index() {
        let service = PhoneStateService::new(InMemoryPhoneRepository::new());

        let message = service
            .send_message(
                "sender".to_string(),
                "receiver".to_string(),
                "Test".to_string(),
                "123".to_string(),
            )
            .expect("message should send");

        assert!(
            service
                .delete_message("sender".to_string(), message.id.clone())
                .expect("message should delete")
        );
        assert!(
            service
                .list_messages("sender".to_string())
                .expect("sender messages should load")
                .is_empty()
        );
        assert_eq!(
            service
                .list_messages("receiver".to_string())
                .expect("receiver messages should load")
                .len(),
            1
        );
    }

    #[test]
    fn delete_email_removes_requesting_users_index() {
        let service = PhoneStateService::new(InMemoryPhoneRepository::new());

        let email = service
            .send_email(
                "sender".to_string(),
                "receiver".to_string(),
                "Subject".to_string(),
                "Body".to_string(),
                "123".to_string(),
            )
            .expect("email should send");

        assert!(
            service
                .delete_email("receiver".to_string(), email.id.clone())
                .expect("email should delete")
        );
        assert!(
            service
                .list_emails("receiver".to_string())
                .expect("receiver emails should load")
                .is_empty()
        );
        assert_eq!(
            service
                .list_emails("sender".to_string())
                .expect("sender emails should remain")
                .len(),
            1
        );
    }
}
