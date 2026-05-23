//! ICOM (Internal Communication) module for inter-server communication
//!
//! This module provides functionality for Arma 3 servers to communicate with each other
//! through a central ICOM hub server. It enables real-time event passing between multiple
//! game servers, allowing for synchronized gameplay experiences.
//!
//! # Architecture
//!
//! - **Extension Module**: This code runs inside the Arma 3 server extension
//! - **ICOM Client**: Connects to the central ICOM server on initialization
//! - **Event Listener**: Spawned task that continuously listens for incoming events
//! - **Event Forwarder**: Receives events and forwards them to Arma via callbacks
//!
//! # Event Flow
//!
//! 1. **Outgoing**: SQF → Extension command → ICOM client → ICOM server → Target server
//! 2. **Incoming**: ICOM server → Event listener → Forward helper → Arma callback → SQF
//!
//! # Usage from SQF
//!
//! ```sqf
//! // Send event to specific server
//! "forge_server" callExtension ["icom:send_event", ["server_2", "supply_drop", '{"coords":[1234,5678,0]}']]
//!
//! // Broadcast to all servers
//! "forge_server" callExtension ["icom:broadcast", ["global_alert", '{"message":"Event starting"}']]
//!
//! // Handle incoming events
//! ["forge_icom_event", {
//!     params ["_eventName", "_data"];
//!     // Process event based on _eventName
//! }] call CBA_fnc_addEventHandler;
//! ```

use arma_rs::{Context, Group};
use forge_icom::Message;
use forge_icom::client::IComClient;
use std::sync::OnceLock;

use crate::{CONTEXT, RUNTIME, log};

/// Global ICOM client, created once and shared by all commands.
/// Initialized asynchronously after extension loads.
pub static ICOM_CLIENT: OnceLock<IComClient> = OnceLock::new();

/// Initialize ICOM client connection
///
/// Establishes connection to the ICOM server and spawns a background listener task.
/// This function is called during extension startup (from `lib.rs`) or manually via
/// the `icom:connect` command.
///
/// # Process
///
/// 1. Stores Arma context globally for use in event forwarding callbacks
/// 2. Connects to ICOM server and registers with the provided server ID
/// 3. Spawns persistent listener task on the runtime's thread pool
/// 4. Listener automatically forwards incoming events to Arma via CBA
///
/// # Arguments
///
/// * `ctx` - Arma extension context for triggering CBA callbacks
/// * `address` - ICOM server address (e.g., "127.0.0.1:9090")
/// * `server_id` - Unique identifier for this server (e.g., "server_1")
///
/// # Behavior
///
/// - If connection fails, a warning is logged but the extension continues
/// - If already connected, logs an error and returns
/// - Listener runs indefinitely until connection is lost or extension unloads
pub async fn initialize(ctx: Context, address: String, server_id: String) {
    // Store context in global CONTEXT
    *CONTEXT.write().await = Some(ctx);
    match IComClient::connect(&address, server_id).await {
        Ok(client) => {
            if ICOM_CLIENT.set(client).is_ok() {
                log::log("icom", "INFO", "Connected to ICOM server");

                // Spawn listener task
                RUNTIME.spawn(async move {
                    if let Some(client) = ICOM_CLIENT.get() {
                        let result = client
                            .listen_for_events(|msg| {
                                if let Message::Event {
                                    event_name, data, ..
                                } = msg
                                {
                                    log::log(
                                        "icom",
                                        "INFO",
                                        &format!("Received event '{}': {}", event_name, data),
                                    );

                                    // Forward event to Arma
                                    forward(&event_name, &data);
                                }
                                Ok(())
                            })
                            .await;

                        if let Err(e) = result {
                            log::log("icom", "ERROR", &format!("Event listener error: {}", e));
                        }
                    }
                });
            } else {
                log::log("icom", "ERROR", "Failed to set ICOM client (already set)");
            }
        }
        Err(e) => {
            log::log(
                "icom",
                "WARN",
                &format!("Failed to connect to ICOM server: {}", e),
            );
        }
    }
}

/// Create ICOM command group
///
/// Builds the command group exposed to SQF under the `icom:` namespace.
///
/// # Available Commands
///
/// - `connect` - Connect to the ICOM server manually
/// - `send_event` - Send event to a specific server
/// - `broadcast` - Broadcast event to all connected servers
pub fn group() -> Group {
    Group::new()
        .command("connect", connect)
        .command("broadcast", broadcast)
        .command("send_event", send_event)
}

/// Connect to ICOM server from SQF
///
/// Initiates connection to the ICOM server with custom parameters. Useful for:
/// - Retrying after initial connection failure
/// - Connecting to non-default ICOM server address
/// - Setting server ID at runtime instead of compile-time
///
/// The connection process runs asynchronously in the background. Check logs
/// for success/failure status.
///
/// # Arguments
///
/// * `ctx` - Arma extension context (automatically provided by arma-rs)
/// * `address` - ICOM server address (e.g., "127.0.0.1:9090")
/// * `server_id` - Unique server identifier (e.g., "server_1", "server_2")
///
/// # Returns
///
/// - `"Connection initiated"` - Background connection task started successfully
/// - `"ERROR: Already connected"` - Client is already connected (disconnect first)
///
/// # SQF Usage
///
/// ```sqf
/// private _result = "forge_server" callExtension ["icom:connect", ["127.0.0.1:9090", "server_1"]];
/// systemChat _result; // "Connection initiated"
/// // Check @forge_server/logs/icom.log for connection status
/// ```
fn connect(ctx: Context, address: String, server_id: String) -> String {
    if ICOM_CLIENT.get().is_some() {
        return "ERROR: Already connected".to_string();
    }

    RUNTIME.spawn(async move {
        log::log(
            "icom",
            "INFO",
            &format!("Connecting to {} as {}", address, server_id),
        );

        initialize(ctx, address, server_id).await;
    });

    "Connection initiated".to_string()
}

/// Broadcast an event to all connected servers
///
/// Sends an event to all servers currently connected to the ICOM hub,
/// except the sender itself.
///
/// # Arguments
///
/// * `event_name` - Name of the event (e.g., "global_alert", "server_restart")
/// * `data` - JSON string containing event data
///
/// # Returns
///
/// - `"OK"` if the broadcast was sent successfully
/// - `"ERROR: <reason>"` if broadcast failed
///
/// # SQF Usage
///
/// ```sqf
/// private _result = "forge_server" callExtension [
///     "icom:broadcast",
///     ["global_alert", '{"message":"Server restart in 5 minutes","severity":"warning"}']
/// ];
/// ```
fn broadcast(event_name: String, data: String) -> String {
    let client = match ICOM_CLIENT.get() {
        Some(c) => c,
        None => {
            log::log("icom", "ERROR", "ICOM client not connected");
            return "ERROR: Not connected to ICOM server".to_string();
        }
    };

    // Parse JSON data
    let json_data: serde_json::Value = match serde_json::from_str(&data) {
        Ok(d) => d,
        Err(e) => {
            log::log("icom", "ERROR", &format!("Invalid JSON data: {}", e));
            return format!("ERROR: Invalid JSON - {}", e);
        }
    };

    log::log(
        "icom",
        "INFO",
        &format!("Broadcasting event '{}'", event_name),
    );

    // Broadcast the event asynchronously
    RUNTIME.spawn(async move {
        if let Err(e) = client.broadcast(&event_name, json_data).await {
            log::log("icom", "ERROR", &format!("Failed to send event: {}", e));
        }
    });

    "OK".to_string()
}

/// Send an event to a specific server
///
/// Sends a custom event with arbitrary JSON data to another server connected to ICOM.
///
/// # Arguments
///
/// * `target_server` - The server ID to send the event to (e.g., "server_2")
/// * `event_name` - Name of the event (e.g., "supply_drop", "spawn_mission")
/// * `data` - JSON string containing event data
///
/// # Returns
///
/// - `"OK"` if the event was sent successfully
/// - `"ERROR: <reason>"` if sending failed
///
/// # SQF Usage
///
/// ```sqf
/// private _result = "forge_server" callExtension [
///     "icom:send_event",
///     ["server_2", "supply_drop", '{"coords":[1234,5678,0],"supplies":["ammo","medical"]}']
/// ];
/// ```
fn send_event(target_server: String, event_name: String, data: String) -> String {
    let client = match ICOM_CLIENT.get() {
        Some(c) => c,
        None => {
            log::log("icom", "ERROR", "ICOM client not connected");
            return "ERROR: Not connected to ICOM server".to_string();
        }
    };

    // Parse JSON data
    let json_data: serde_json::Value = match serde_json::from_str(&data) {
        Ok(d) => d,
        Err(e) => {
            log::log("icom", "ERROR", &format!("Invalid JSON data: {}", e));
            return format!("ERROR: Invalid JSON - {}", e);
        }
    };

    log::log(
        "icom",
        "INFO",
        &format!("Sending event '{}' to '{}'", event_name, target_server),
    );

    // Send the event asynchronously
    RUNTIME.spawn(async move {
        if let Err(e) = client
            .send_event(&target_server, &event_name, json_data)
            .await
        {
            log::log("icom", "ERROR", &format!("Failed to send event: {}", e));
        }
    });

    "OK".to_string()
}

/// Forward an ICOM event to Arma via callback
///
/// Internal helper function that takes an event received from ICOM and forwards it
/// to Arma 3 via the callback mechanism. The event is sent to SQF as a JSON array:
/// `["event_name", {data}]`
///
/// # Arguments
///
/// * `event_name` - The name of the event
/// * `data` - The event data as a JSON value
///
/// # Implementation Notes
///
/// Uses `try_read()` instead of blocking to avoid deadlocks when called from within
/// an async task running on the same runtime that manages the context lock.
///
/// The callback triggers the "forge_icom_event" CBA event in Arma, which should be
/// handled by mission code to process incoming inter-server events.
fn forward(event_name: &str, data: &serde_json::Value) {
    // Use try_read to avoid blocking inside async context
    let context_guard = match CONTEXT.try_read() {
        Ok(guard) => guard,
        Err(_) => {
            log::log("icom", "WARN", "Could not acquire CONTEXT read lock");
            return;
        }
    };

    if let Some(ctx) = context_guard.as_ref() {
        // Format as JSON array: ["event_name", data]
        let event_data = serde_json::json!([event_name, data]);
        let event_json =
            serde_json::to_string(&event_data).unwrap_or_else(|_| "[\"error\",null]".to_string());

        match ctx.callback_data("icom", "forge_icom_event", Some(event_json)) {
            Ok(_) => {
                log::log(
                    "icom",
                    "INFO",
                    &format!("Forwarded event '{}' to Arma", event_name),
                );
            }
            Err(e) => {
                log::log(
                    "icom",
                    "ERROR",
                    &format!("Failed to forward event to Arma: {}", e),
                );
            }
        }
    } else {
        log::log("icom", "WARN", "Context not available for callback");
    }
}
