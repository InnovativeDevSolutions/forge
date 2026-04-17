# Forge ICOM Server (Internal Communication)

A standalone TCP server for inter-Arma3-server communication. ICOM enables multiple Arma 3 servers to communicate with each other, facilitating cross-server events like mission spawning, supply drops, and military reports.

## Architecture

```
[Arma Server 1] <---> [Forge ICOM] <---> [Arma Server 2]
   (Extension)         (TCP 9090)           (Extension)
      Client                                    Client
```

Each Arma server's extension connects to the ICOM server as a client. ICOM routes messages between servers based on target IDs or broadcasts to all connected servers.

## Configuration

The ICOM server can be configured using a `config.toml` file. Create one from the example:

```powershell
cp bin/icom/config.example.toml config.toml
```

Place `config.toml` in the same directory as the `forge-icom` executable or in the current working directory.

### Configuration Options

```toml
[server]
# Host to bind to
# "0.0.0.0" = All interfaces (allows remote connections)
# "127.0.0.1" = Localhost only
host = "0.0.0.0"

# Port to listen on
port = 9090
```

**Defaults**: If no config file is found, defaults to `0.0.0.0:9090`.

## Building

```powershell
# Build release binary
cargo build --release -p forge-icom

# The executable will be at:
# target/release/forge-icom.exe (Windows)
```

## Running

```powershell
# Run the ICOM server
./target/release/forge-icom.exe

# Or during development
cargo run -p forge-icom
```

The server will listen on `0.0.0.0:9090` by default.

## Design Philosophy

### Generic Event System

ICOM uses a **generic event-based architecture** instead of predefined message types. This means:

- ✅ **Flexibility**: Add new event types without changing the ICOM server code
- ✅ **Simplicity**: Only one `Event` message type instead of multiple specialized types
- ✅ **Decoupled**: ICOM doesn't need to know about your game logic
- ✅ **Future-proof**: Easy to extend as your needs evolve

ICOM simply routes events between servers - your application logic determines what each event means.

## Message Protocol

All messages are JSON objects sent as newline-delimited strings. Each message has a `type` field that determines its structure.

### Register

First message from each Arma server to identify itself:

```json
{
    "type": "register",
    "server_id": "server_1"
}
```

Response:

```json
{
    "type": "registered",
    "session_id": "uuid-here"
}
```

### Event (Send to Specific Server)

Send an event with arbitrary JSON data to a specific server:

```json
{
    "type": "event",
    "target_server": "server_2",
    "event_name": "supply_drop",
    "data": {
        "coords": [1234.5, 5678.9, 0.0],
        "supplies": ["ammo_box", "medical_supplies"]
    }
}
```

Another example:

```json
{
    "type": "event",
    "target_server": "server_2",
    "event_name": "spawn_mission",
    "data": {
        "mission_type": "convoy_ambush",
        "difficulty": "hard",
        "location": [1234, 5678, 0]
    }
}
```

### Broadcast

Send event to all connected servers (except sender):

```json
{
    "type": "broadcast",
    "event_name": "global_alert",
    "data": {
        "message": "Nuclear strike incoming!",
        "severity": "critical"
    }
}
```

### Acknowledgment

Response to successful message delivery:

```json
{
    "type": "ack",
    "message_id": null,
    "success": true,
    "error": null
}
```

Error response:

```json
{
    "type": "ack",
    "message_id": null,
    "success": false,
    "error": "Target server 'server_3' not found"
}
```

## Integration with Arma Extension

### Client Library

The `forge-icom` crate includes a `client` module that provides a high-level API for connecting to ICOM:

```rust
use forge_icom::client::IComClient;
use forge_icom::Message;
use serde_json::json;

// Connect and register (automatically handles registration)
let client = IComClient::connect("127.0.0.1:9090", "server_1".to_string()).await?;

// Send event to another server
client.send_event(
    "server_2",
    "supply_drop",
    json!({
        "coords": [1234.5, 5678.9, 0.0],
        "supplies": ["ammo", "medical"]
    })
).await?;

// Broadcast to all servers
client.broadcast(
    "global_alert",
    json!({"message": "Server restart in 5 minutes"})
).await?;

// Listen for incoming events
client.listen_for_events(|msg| {
    match msg {
        Message::Event { event_name, data, .. } => {
            // Forward to Arma via callback
        }
        _ => {}
    }
    Ok(())
}).await?;
```

### Extension Integration

The Forge server extension includes full ICOM integration:

1. **Initialization**: Connects to ICOM on extension startup (or manually via `icom:connect`)
2. **Event Listener**: Spawns background task to receive events continuously
3. **Callback System**: Forwards events to Arma via CBA event handlers
4. **Extension Commands**: Provides SQF commands to send/receive events

**Important Notes**:

- The extension uses `try_read()` to avoid deadlocks when accessing context from async tasks
- Broadcast events are **not** sent back to the originating server
- Connection can be initiated manually if automatic startup connection fails

### SQF Usage

#### Connecting to ICOM

```sqf
// Connect manually (if not using automatic startup connection)
private _result = "forge_server" callExtension ["icom:connect", ["127.0.0.1:9090", "server_1"]];
systemChat _result; // "Connection initiated" or "ERROR: Already connected"
```

#### Sending Events

```sqf
// Send event to specific server
private _data = createHashMapFromArray [
    ["coords", [1234, 5678, 0]],
    ["supplies", ["ammo_box", "medical_supplies"]]
];
"forge_server" callExtension ["icom:send_event", ["server_2", "supply_drop", (toJSON _data)]];

// Spawn mission on another server
private _missionData = createHashMapFromArray [
    ["mission_type", "convoy_ambush"],
    ["difficulty", "hard"],
    ["location", [1234, 5678, 0]]
];
"forge_server" callExtension ["icom:send_event", ["server_2", "spawn_mission", (toJSON _missionData)]];

// Broadcast to all servers (except sender)
private _alertData = createHashMapFromArray [
    ["message", "Nuclear strike incoming!"],
    ["severity", "critical"]
];
"forge_server" callExtension ["icom:broadcast", ["global_alert", (toJSON _alertData)]];
```

#### Receiving Events

Handle incoming events with a CBA event handler:

```sqf
["forge_icom_event", {
    params ["_eventName", "_data"];

    switch (_eventName) do {
        case "supply_drop": {
            private _coords = _data get "coords";
            private _supplies = _data get "supplies";
            // Create supply drop at coordinates
            [_coords, _supplies] call YourMod_fnc_createSupplyDrop;
        };
        case "spawn_mission": {
            private _missionType = _data get "mission_type";
            private _location = _data get "location";
            // Spawn the mission
            [_missionType, _location] call YourMod_fnc_spawnMission;
        };
        case "global_alert": {
            private _message = _data get "message";
            // Show alert to all players
            [_message] remoteExec ["hint", 0];
        };
        default {
            diag_log format ["[ICOM] Unhandled event: %1", _eventName];
        };
    };
}] call CBA_fnc_addEventHandler;
```

## Production Deployment

### As Windows Service

You can run ICOM as a Windows service using tools like NSSM:

```powershell
# Install NSSM
winget install NSSM.NSSM

# Create service
nssm install ForgeICOM "C:\path\to\forge-icom.exe"
nssm start ForgeICOM
```

### Docker (for Linux servers)

```dockerfile
FROM rust:1.70 as builder
WORKDIR /app
COPY . .
RUN cargo build --release -p forge-icom

FROM debian:bookworm-slim
COPY --from=builder /app/target/release/forge-icom /usr/local/bin/
EXPOSE 9090
CMD ["forge-icom"]
```

```bash
docker build -t forge-icom .
docker run -d -p 9090:9090 --name forge-icom forge-icom
```

## Features

- **Async I/O**: Non-blocking message handling using Tokio
- **Multiple connections**: Handle dozens of Arma servers simultaneously
- **Generic event system**: Send arbitrary JSON data without predefined message types
- **Message routing**: Direct events to specific servers or broadcast to all
- **Session management**: Track connected servers with UUIDs
- **Duplicate connection handling**: Automatically replaces old connections when server reconnects
- **Automatic cleanup**: Remove disconnected servers from registry
- **Graceful error handling**: Clients continue running even when target servers are offline

## Testing

### Running Examples

```powershell
# Terminal 1: Start ICOM server
cargo run --bin forge-icom

# Terminal 2: Start server_1 (listener)
cargo run --example server_1_client

# Terminal 3: Start server_2 (sender)
cargo run --example server_2_client
```

You should see events flow from server_2 → ICOM → server_1.

### Test with Extension

1. Start ICOM server
2. Start Arma 3 server with Forge extension
3. In Arma, connect manually (if needed):
    ```sqf
    "forge_server" callExtension ["icom:connect", ["127.0.0.1:9090", "server_1"]]
    ```
4. Set up CBA event handler in mission init:
    ```sqf
    ["forge_icom_event", {
        params ["_eventName", "_data"];
        systemChat format ["ICOM Event: %1", _eventName];
    }] call CBA_fnc_addEventHandler;
    ```
5. Run example sender client to test event reception:
    ```powershell
    cargo run --example server_2_client
    ```
6. Check logs at `@forge_server/logs/icom.log` to verify events are received

## Next Steps

1. **Run the examples** to see the system in action
2. **Add CBA event handler** in your mission to process `forge_icom_event`
3. **Define your event types** (supply_drop, spawn_mission, etc.) based on your needs
4. **Test with multiple Arma servers** locally
5. **Deploy ICOM server** to production (Windows Service or Docker)
6. **Configure server IDs** in extension config for each server

## Monitoring

The ICOM server logs all important events to stdout:

- 🔥 Server startup
- 📡 New connections
- ✅ Server registrations
- 📢 Broadcast messages
- 📨 Message forwarding
- 🗑️ Server disconnections
- ❌ Errors

Consider redirecting output to a file or logging service for production.
