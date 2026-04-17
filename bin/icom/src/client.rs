//! Forge Internal Communication (ICOM) Client Library
//!
//! This library provides a client for connecting to the Forge ICOM Server
//! and sending/receiving events between Arma 3 servers.
//!
//! # Overview
//!
//! The ICOM client handles:
//! - **Connection Management**: Connects to ICOM server and maintains persistent connection
//! - **Registration**: Identifies itself with a unique server ID
//! - **Event Sending**: Send events to specific servers or broadcast to all
//! - **Event Listening**: Continuously listen for incoming events from other servers
//!
//! # Usage
//!
//! ```no_run
//! use forge_icom::client::IComClient;
//! use serde_json::json;
//!
//! #[tokio::main]
//! async fn main() -> Result<(), Box<dyn std::error::Error>> {
//!     // Connect and register
//!     let client = IComClient::connect("127.0.0.1:9090", "server_1".to_string()).await?;
//!
//!     // Send an event to another server
//!     client.send_event(
//!         "server_2",
//!         "supply_drop",
//!         json!({"coords": [1234, 5678, 0]})
//!     ).await?;
//!
//!     // Listen for incoming events
//!     client.listen_for_events(|msg| {
//!         // Handle event...
//!         Ok(())
//!     }).await?;
//!
//!     Ok(())
//! }
//! ```

pub use crate::Message;
use std::sync::Arc;
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::TcpStream;
use tokio::sync::Mutex;

/// ICOM client for connecting to the Forge ICOM Server
///
/// The client maintains a persistent TCP connection to the ICOM server and uses
/// separate reader/writer halves wrapped in Arc<Mutex<>> to allow safe concurrent
/// access from multiple tasks.
///
/// # Thread Safety
///
/// The client is designed to be safely shared across multiple async tasks. The
/// internal reader and writer are protected by mutexes, allowing concurrent
/// send/receive operations.
pub struct IComClient {
    writer: Arc<Mutex<tokio::net::tcp::OwnedWriteHalf>>,
    reader: Arc<Mutex<BufReader<tokio::net::tcp::OwnedReadHalf>>>,
    server_id: String,
}

impl IComClient {
    /// Connect to the ICOM server and register
    ///
    /// Establishes a TCP connection to the ICOM server, sends a registration message,
    /// and waits for confirmation before returning. If registration fails, an error
    /// is returned.
    ///
    /// # Arguments
    ///
    /// * `icom_addr` - Address of the ICOM server (e.g., "127.0.0.1:9090")
    /// * `server_id` - Unique identifier for this server (e.g., "server_1", "server_2")
    ///
    /// # Returns
    ///
    /// Returns a connected and registered `IComClient` on success, or an error if
    /// connection or registration fails.
    ///
    /// # Example
    ///
    /// ```no_run
    /// use forge_icom::client::IComClient;
    ///
    /// # async fn example() -> Result<(), Box<dyn std::error::Error>> {
    /// let client = IComClient::connect("127.0.0.1:9090", "server_1".to_string()).await?;
    /// # Ok(())
    /// # }
    /// ```
    pub async fn connect(
        icom_addr: &str,
        server_id: String,
    ) -> Result<Self, Box<dyn std::error::Error>> {
        let stream = TcpStream::connect(icom_addr).await?;
        let (reader, writer) = stream.into_split();

        let client = Self {
            writer: Arc::new(Mutex::new(writer)),
            reader: Arc::new(Mutex::new(BufReader::new(reader))),
            server_id: server_id.clone(),
        };

        // Register with ICOM
        let register_msg = Message::Register {
            server_id: server_id.clone(),
        };
        client.send_message(&register_msg).await?;

        // Wait for registration confirmation
        let response = client.receive_message().await?;
        match response {
            Message::Registered { .. } => Ok(client),
            _ => Err("Failed to register with ICOM".into()),
        }
    }

    /// Send a message to ICOM
    ///
    /// Internal method that serializes a message to JSON and sends it over the wire,
    /// terminated with a newline character.
    async fn send_message(&self, msg: &Message) -> Result<(), Box<dyn std::error::Error>> {
        let json = serde_json::to_string(msg)?;
        let mut writer = self.writer.lock().await;
        writer.write_all(json.as_bytes()).await?;
        writer.write_all(b"\n").await?;
        Ok(())
    }

    /// Receive a message from ICOM
    ///
    /// Internal method that reads a line-delimited JSON message from the server
    /// and deserializes it into a Message enum.
    async fn receive_message(&self) -> Result<Message, Box<dyn std::error::Error>> {
        let mut reader = self.reader.lock().await;
        let mut line = String::new();
        reader.read_line(&mut line).await?;
        let msg = serde_json::from_str(&line)?;
        Ok(msg)
    }

    /// Send an event to another server
    ///
    /// Sends a custom event with arbitrary JSON data to a specific server connected
    /// to the ICOM hub. The method waits for an acknowledgment from the server before
    /// returning.
    ///
    /// # Arguments
    ///
    /// * `target_server` - ID of the target server (must be currently connected)
    /// * `event_name` - Name of the event (e.g., "supply_drop", "spawn_mission")
    /// * `data` - Arbitrary JSON data for the event
    ///
    /// # Returns
    ///
    /// Returns `Ok(())` if the event was successfully sent and acknowledged, or an
    /// error if the target server is not found or communication fails.
    ///
    /// # Example
    ///
    /// ```no_run
    /// use forge_icom::client::IComClient;
    /// use serde_json::json;
    ///
    /// # async fn example(client: &IComClient) -> Result<(), Box<dyn std::error::Error>> {
    /// client.send_event(
    ///     "server_2",
    ///     "supply_drop",
    ///     json!({
    ///         "coords": [1234.5, 5678.9, 0.0],
    ///         "supplies": ["ammo", "medical"]
    ///     })
    /// ).await?;
    /// # Ok(())
    /// # }
    /// ```
    pub async fn send_event(
        &self,
        target_server: &str,
        event_name: &str,
        data: serde_json::Value,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let msg = Message::Event {
            target_server: target_server.to_string(),
            event_name: event_name.to_string(),
            data,
        };
        self.send_message(&msg).await?;

        // Wait for acknowledgment
        let ack = self.receive_message().await?;
        match ack {
            Message::Ack { success: true, .. } => Ok(()),
            Message::Ack { error: Some(e), .. } => Err(e.into()),
            _ => Err("Unexpected response".into()),
        }
    }

    /// Broadcast an event to all servers
    ///
    /// Sends an event to all servers currently connected to the ICOM hub, except
    /// the sender itself. The method waits for an acknowledgment before returning.
    ///
    /// # Arguments
    ///
    /// * `event_name` - Name of the event (e.g., "global_alert", "server_restart")
    /// * `data` - Arbitrary JSON data for the event
    ///
    /// # Returns
    ///
    /// Returns `Ok(())` if the broadcast was successfully sent and acknowledged,
    /// or an error if communication fails.
    ///
    /// # Example
    ///
    /// ```no_run
    /// use forge_icom::client::IComClient;
    /// use serde_json::json;
    ///
    /// # async fn example(client: &IComClient) -> Result<(), Box<dyn std::error::Error>> {
    /// client.broadcast(
    ///     "global_alert",
    ///     json!({
    ///         "message": "Nuclear strike incoming!",
    ///         "severity": "critical"
    ///     })
    /// ).await?;
    /// # Ok(())
    /// # }
    /// ```
    pub async fn broadcast(
        &self,
        event_name: &str,
        data: serde_json::Value,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let msg = Message::Broadcast {
            event_name: event_name.to_string(),
            data,
        };
        self.send_message(&msg).await?;

        // Wait for acknowledgment
        let ack = self.receive_message().await?;
        match ack {
            Message::Ack { success: true, .. } => Ok(()),
            Message::Ack { error: Some(e), .. } => Err(e.into()),
            _ => Err("Unexpected response".into()),
        }
    }

    /// Start listening for incoming messages from other servers
    ///
    /// Enters an infinite loop that continuously receives messages from the ICOM server
    /// and passes them to the provided handler function. This method blocks until an
    /// error occurs or the connection is closed.
    ///
    /// # Arguments
    ///
    /// * `handler` - Callback function invoked for each received message. Should return
    ///   `Ok(())` to continue listening, or an error to stop.
    ///
    /// # Returns
    ///
    /// Returns an error if the connection is lost or if the handler returns an error.
    ///
    /// # Example
    ///
    /// ```no_run
    /// use forge_icom::client::IComClient;
    /// use forge_icom::Message;
    ///
    /// # async fn example(client: &IComClient) -> Result<(), Box<dyn std::error::Error>> {
    /// client.listen_for_events(|msg| {
    ///     match msg {
    ///         Message::Event { event_name, data, .. } => {
    ///             println!("Received event: {} with data: {:?}", event_name, data);
    ///         }
    ///         _ => {}
    ///     }
    ///     Ok(())
    /// }).await?;
    /// # Ok(())
    /// # }
    /// ```
    pub async fn listen_for_events<F>(
        &self,
        mut handler: F,
    ) -> Result<(), Box<dyn std::error::Error>>
    where
        F: FnMut(Message) -> Result<(), Box<dyn std::error::Error>>,
    {
        loop {
            let msg = self.receive_message().await?;
            handler(msg)?;
        }
    }

    /// Get the server ID for this client
    ///
    /// Returns the unique identifier this client registered with when connecting
    /// to the ICOM server.
    pub fn server_id(&self) -> &str {
        &self.server_id
    }
}
