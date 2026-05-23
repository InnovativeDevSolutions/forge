//! Phone hot-state operations for the Arma 3 server extension.
//!
//! The extension owns phone runtime state for contacts, messages, and emails.
//! SQF remains the event bridge and may enrich contact identity from actor state.

use crate::storage::PhoneStorageRepository;
use arma_rs::Group;
use forge_services::PhoneStateService;
use serde::Serialize;
use std::sync::LazyLock;

static PHONE_SERVICE: LazyLock<PhoneStateService<PhoneStorageRepository>> =
    LazyLock::new(|| PhoneStateService::new(PhoneStorageRepository::configured()));

pub fn group() -> Group {
    Group::new()
        .command("init", init_phone)
        .group(
            "contacts",
            Group::new()
                .command("list", list_contacts)
                .command("add", add_contact)
                .command("remove", remove_contact),
        )
        .group(
            "messages",
            Group::new()
                .command("list", list_messages)
                .command("thread", message_thread)
                .command("send", send_message)
                .command("mark_read", mark_message_read)
                .command("delete", delete_message),
        )
        .group(
            "emails",
            Group::new()
                .command("list", list_emails)
                .command("send", send_email)
                .command("mark_read", mark_email_read)
                .command("delete", delete_email),
        )
        .command("remove", remove_phone)
}

pub(crate) fn init_phone(uid: String) -> String {
    serialize_json(PHONE_SERVICE.init(uid))
}

pub(crate) fn list_contacts(uid: String) -> String {
    serialize_json(PHONE_SERVICE.list_contacts(uid))
}

pub(crate) fn add_contact(uid: String, contact_uid: String) -> String {
    serialize_bool(PHONE_SERVICE.add_contact(uid, contact_uid))
}

pub(crate) fn remove_contact(uid: String, contact_uid: String) -> String {
    serialize_bool(PHONE_SERVICE.remove_contact(uid, contact_uid))
}

pub(crate) fn send_message(
    from_uid: String,
    to_uid: String,
    message: String,
    timestamp: String,
) -> String {
    serialize_json(PHONE_SERVICE.send_message(from_uid, to_uid, message, timestamp))
}

pub(crate) fn list_messages(uid: String) -> String {
    serialize_json(PHONE_SERVICE.list_messages(uid))
}

pub(crate) fn message_thread(uid: String, other_uid: String) -> String {
    serialize_json(PHONE_SERVICE.message_thread(uid, other_uid))
}

pub(crate) fn mark_message_read(uid: String, message_id: String) -> String {
    serialize_bool(PHONE_SERVICE.mark_message_read(uid, message_id))
}

pub(crate) fn delete_message(uid: String, message_id: String) -> String {
    serialize_bool(PHONE_SERVICE.delete_message(uid, message_id))
}

pub(crate) fn send_email(
    from_uid: String,
    to_uid: String,
    subject: String,
    body: String,
    timestamp: String,
) -> String {
    serialize_json(PHONE_SERVICE.send_email(from_uid, to_uid, subject, body, timestamp))
}

pub(crate) fn list_emails(uid: String) -> String {
    serialize_json(PHONE_SERVICE.list_emails(uid))
}

pub(crate) fn mark_email_read(uid: String, email_id: String) -> String {
    serialize_bool(PHONE_SERVICE.mark_email_read(uid, email_id))
}

pub(crate) fn delete_email(uid: String, email_id: String) -> String {
    serialize_bool(PHONE_SERVICE.delete_email(uid, email_id))
}

pub(crate) fn remove_phone(uid: String) -> String {
    match PHONE_SERVICE.remove(uid) {
        Ok(()) => "OK".to_string(),
        Err(error) => format!("Error: {error}"),
    }
}

fn serialize_bool(result: Result<bool, String>) -> String {
    match result {
        Ok(value) => value.to_string(),
        Err(error) => format!("Error: {error}"),
    }
}

fn serialize_json<T: Serialize>(result: Result<T, String>) -> String {
    match result {
        Ok(value) => serde_json::to_string(&value)
            .unwrap_or_else(|error| format!("Error: Failed to serialize phone state: {error}")),
        Err(error) => format!("Error: {error}"),
    }
}
