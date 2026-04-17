//! Forge Internal Communication (ICOM) - Message Types
//!
//! This library exposes the shared `Message` enum used for communication
//! between the ICOM server and clients.

use serde::{Deserialize, Serialize};

pub mod client;

/// Message types for inter-server communication via ICOM
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum Message {
    /// Register a server with a unique ID
    Register { server_id: String },
    /// Server successfully registered
    Registered { session_id: String },
    /// Send event to specific server
    Event {
        target_server: String,
        event_name: String,
        data: serde_json::Value,
    },
    /// Broadcast event to all servers (except sender)
    Broadcast {
        event_name: String,
        data: serde_json::Value,
    },
    /// Response/acknowledgment
    Ack {
        message_id: Option<String>,
        success: bool,
        error: Option<String>,
    },
    /// Error message
    Error { message: String },
}
