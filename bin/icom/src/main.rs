//! Forge ICOM (Internal Communication) Server
//!
//! A centralized hub server that enables real-time communication between multiple
//! Arma 3 game servers. The server maintains persistent connections with each game
//! server and routes events between them.
//!
//! # Architecture
//!
//! - **TCP Server**: Listens on port 9090 for incoming connections
//! - **Server Registry**: Maintains a map of connected servers by their ID
//! - **Message Router**: Forwards events to specific servers or broadcasts to all
//! - **Session Management**: Handles registration, disconnection, and duplicate connections
//!
//! # Protocol
//!
//! Communication uses line-delimited JSON messages. Each message is a JSON object
//! terminated with a newline character (`\n`).
//!
//! ## Message Types
//!
//! - **Register**: Client identifies itself with a server_id
//! - **Event**: Send event to a specific server
//! - **Broadcast**: Send event to all connected servers
//! - **Ack**: Acknowledgment of message receipt
//! - **Error**: Error notification
//!
//! # Usage
//!
//! ```bash
//! # Start the ICOM server
//! cargo run --bin forge-icom
//! ```
//!
//! The server will listen on `0.0.0.0:9090` and accept connections from game servers.

use forge_icom::Message;
use std::collections::HashMap;
use std::net::SocketAddr;
use std::sync::Arc;
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::{TcpListener, TcpStream};
use tokio::sync::{RwLock, mpsc, oneshot};
use uuid::Uuid;

mod config;

/// Represents a connected Arma server
///
/// Each connected server has:
/// - A unique server_id chosen by the client
/// - The socket address they connected from
/// - A message sender channel for outgoing messages
/// - A kill switch to terminate old connections when server reconnects
#[allow(dead_code)]
struct ServerConnection {
    server_id: String,
    addr: SocketAddr,
    tx: mpsc::UnboundedSender<String>,
    kill_tx: oneshot::Sender<()>,
}

/// Shared state across all connections
///
/// The registry is wrapped in Arc<RwLock<>> to allow safe concurrent access
/// from multiple connection handler tasks.
type ServerRegistry = Arc<RwLock<HashMap<String, ServerConnection>>>;

/// Main entry point for the ICOM server
///
/// Initializes the TCP listener and spawns a new task for each incoming connection.
/// The server runs indefinitely until interrupted (Ctrl+C) or encounters a fatal error.
///
/// # Connection Handling
///
/// Each connection is handled independently in its own async task, allowing the server
/// to manage many simultaneous connections efficiently.
#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("🔥 Forge ICOM Server starting...");
    println!();

    // Load configuration
    let config = config::load();
    let addr = config.server.bind_address();

    println!();
    println!("Binding to {}", addr);
    let listener = TcpListener::bind(&addr).await?;
    println!("Server ready - listening for connections");

    let registry: ServerRegistry = Arc::new(RwLock::new(HashMap::new()));

    loop {
        let (socket, addr) = listener.accept().await?;
        println!("New connection from {}", addr);

        let registry = Arc::clone(&registry);
        tokio::spawn(async move {
            if let Err(e) = handle_connection(socket, addr, registry).await {
                eprintln!("Error handling connection from {}: {}", addr, e);
            }
        });
    }
}

/// Handle an individual client connection
///
/// This function manages the lifecycle of a single server connection:
///
/// 1. Splits the socket into reader/writer for bidirectional communication
/// 2. Creates channels for outgoing messages and connection termination
/// 3. Spawns a writer task to handle outgoing messages asynchronously
/// 4. Enters a loop reading incoming messages and dispatching them
/// 5. Cleans up when the connection closes or is terminated
///
/// # Arguments
///
/// * `socket` - The TCP socket for this connection
/// * `addr` - The client's socket address
/// * `registry` - Shared registry of all connected servers
///
/// # Duplicate Connections
///
/// If a server with the same ID connects while already registered, the old
/// connection is terminated via its kill switch, allowing seamless reconnection.
async fn handle_connection(
    socket: TcpStream,
    addr: SocketAddr,
    registry: ServerRegistry,
) -> Result<(), Box<dyn std::error::Error>> {
    let (reader, mut writer) = socket.into_split();
    let mut reader = BufReader::new(reader);

    // Create channel for outgoing messages
    let (tx, mut rx) = mpsc::unbounded_channel::<String>();

    // Create kill switch channel
    let (kill_tx, mut kill_rx) = oneshot::channel::<()>();

    // Spawn task to handle outgoing messages
    let writer_handle = tokio::spawn(async move {
        while let Some(msg) = rx.recv().await {
            if let Err(e) = writer.write_all(msg.as_bytes()).await {
                eprintln!("Failed to write message: {}", e);
                break;
            }
            if let Err(e) = writer.write_all(b"\n").await {
                eprintln!("Failed to write newline: {}", e);
                break;
            }
        }
    });

    let mut server_id: Option<String> = None;
    let mut line = String::new();
    let mut kill_tx = Some(kill_tx);

    loop {
        line.clear();

        let read_future = reader.read_line(&mut line);

        tokio::select! {
            _ = &mut kill_rx => {
                println!("Connection replaced by new session: {}", addr);
                break;
            }
            res = read_future => {
                match res {
                    Ok(0) => {
                        println!("Connection closed by {}", addr);
                        break;
                    }
                    Ok(_) => {
                        let trimmed = line.trim();
                        if trimmed.is_empty() {
                            continue;
                        }

                        match serde_json::from_str::<Message>(trimmed) {
                            Ok(msg) => {
                                match handle_message(msg, &mut server_id, addr, &tx, &registry, &mut kill_tx).await {
                                    Ok(_) => {}
                                    Err(e) => {
                                        let error_msg = Message::Error {
                                            message: e.to_string(),
                                        };
                                        let _ = tx.send(serde_json::to_string(&error_msg)?);
                                    }
                                }
                            }
                            Err(e) => {
                                eprintln!("Failed to parse message from {}: {}", addr, e);
                                let error_msg = Message::Error {
                                    message: format!("Invalid JSON: {}", e),
                                };
                                let _ = tx.send(serde_json::to_string(&error_msg)?);
                            }
                        }
                    }
                    Err(e) => {
                        eprintln!("Error reading from {}: {}", addr, e);
                        break;
                    }
                }
            }
        }
    }

    // Cleanup on disconnect
    if let Some(id) = server_id {
        let mut registry = registry.write().await;
        registry.remove(&id);
        println!("Unregistered server: {}", id);
    }

    writer_handle.abort();
    Ok(())
}

/// Process a received message and route it appropriately
///
/// This function implements the core message routing logic:
///
/// - **Register**: Adds the server to the registry with a new session ID
/// - **Event**: Forwards the event to the target server (or returns error if not found)
/// - **Broadcast**: Sends the event to all registered servers except the sender
/// - **Other**: Echoes back unhandled message types
///
/// # Arguments
///
/// * `msg` - The parsed message to handle
/// * `server_id` - Mutable reference to this connection's server ID (set on registration)
/// * `addr` - The client's socket address (for logging)
/// * `tx` - Channel sender for outgoing messages to this connection
/// * `registry` - Shared registry of all connected servers
/// * `kill_tx` - Kill switch for terminating this connection (consumed on registration)
///
/// # Returns
///
/// Returns `Ok(())` on success, or an error if message processing fails.
async fn handle_message(
    msg: Message,
    server_id: &mut Option<String>,
    addr: SocketAddr,
    tx: &mpsc::UnboundedSender<String>,
    registry: &ServerRegistry,
    kill_tx: &mut Option<oneshot::Sender<()>>,
) -> Result<(), Box<dyn std::error::Error>> {
    match msg {
        Message::Register { server_id: id } => {
            // Register the server
            let session_id = Uuid::new_v4().to_string();

            // Take kill_tx
            let ktx = kill_tx
                .take()
                .ok_or("Cannot register twice or kill handle missing")?;

            let conn = ServerConnection {
                server_id: id.clone(),
                addr,
                tx: tx.clone(),
                kill_tx: ktx,
            };

            {
                let mut registry = registry.write().await;
                if let Some(old) = registry.insert(id.clone(), conn) {
                    println!("Disconnecting old session for {}", id);
                    let _ = old.kill_tx.send(());
                }
            }

            *server_id = Some(id.clone());
            println!("Registered server: {} (session: {})", id, session_id);

            // Send acknowledgment
            let response = Message::Registered { session_id };
            tx.send(serde_json::to_string(&response)?)?;
        }

        Message::Broadcast { event_name, data } => {
            // Broadcast to all servers except sender
            let registry = registry.read().await;
            let sender_id = server_id.as_ref();

            println!("Broadcasting '{}' from {:?}", event_name, sender_id);

            for (id, conn) in registry.iter() {
                if sender_id.map(|s| s == id).unwrap_or(false) {
                    continue; // Skip sender
                }

                let event = Message::Event {
                    target_server: id.clone(),
                    event_name: event_name.clone(),
                    data: data.clone(),
                };

                if let Err(e) = conn.tx.send(serde_json::to_string(&event)?) {
                    eprintln!("Failed to send to {}: {}", id, e);
                }
            }

            // Ack to sender
            let ack = Message::Ack {
                message_id: None,
                success: true,
                error: None,
            };
            tx.send(serde_json::to_string(&ack)?)?;
        }

        Message::Event {
            ref target_server, ..
        } => {
            // Forward to specific server
            let registry = registry.read().await;

            if let Some(target) = registry.get(target_server) {
                println!("Forwarding message to {}", target_server);
                target.tx.send(serde_json::to_string(&msg)?)?;

                // Ack to sender
                let ack = Message::Ack {
                    message_id: None,
                    success: true,
                    error: None,
                };
                tx.send(serde_json::to_string(&ack)?)?;
            } else {
                let error = format!("Target server '{}' not found", target_server);
                let ack = Message::Ack {
                    message_id: None,
                    success: false,
                    error: Some(error),
                };
                tx.send(serde_json::to_string(&ack)?)?;
            }
        }

        _ => {
            // Echo back unhandled messages
            tx.send(serde_json::to_string(&msg)?)?;
        }
    }

    Ok(())
}
