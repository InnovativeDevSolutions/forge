# Framework Architecture

Forge is organized around domain modules. A domain usually has SQF addon
entry points, Rust models, repository traits, service logic, extension command
handlers, and optional browser UI.

## Runtime Flow

![Architectural Flow Diagram](architecture-flow.svg)

```text
Arma client UI or SQF action
  -> client addon bridge
  -> server addon function
  -> forge_server callExtension command
  -> extension command group
  -> forge-services domain service
  -> forge-repositories trait
  -> SurrealDB repository implementation
  -> SurrealDB
```

For small payloads, server SQF calls `forge_server` directly through the
extension bridge. For large payloads, `arma/server/addons/extension` stages
request and response chunks through the extension transport module.

## Main Layers

### Client Addons

Client addons live under `arma/client/addons`. They own local player UX,
keybinds, browser UI dialogs, and UI-to-SQF event handling. When a client needs
durable or authoritative state, it routes work to the matching server addon
instead of touching persistence directly.

### Server Addons

Server addons live under `arma/server/addons`. They own server-side SQF
initialization, game-object integration, validation near the Arma runtime, and
calls into the Rust extension. The `extension` addon is the shared bridge for
`callExtension` and transport handling.

### Rust Extension

The server extension lives under `arma/server/extension`. It registers the
`forge_server` command groups, loads configuration, initializes SurrealDB, and
maps SQF command inputs into service calls.

The extension should stay thin:

- Parse and validate command arguments that arrive from SQF.
- Resolve Arma-specific context such as player UID when required.
- Call the matching service.
- Serialize the service result back to JSON or a simple string.

### Shared Rust Crates

The `lib` workspace contains reusable Rust crates:

- `forge-models`: shared domain structs and serialization rules.
- `forge-repositories`: storage-agnostic repository traits and in-memory
  implementations used by tests and hot-state services.
- `forge-services`: domain behavior, validation, and mutation workflows.
- `forge-shared`: cross-crate helpers.

### Persistence

Durable storage is SurrealDB. Schema modules live under
`arma/server/extension/src/schema`, and concrete SurrealDB repository
implementations live under `arma/server/extension/src/storage`.

Repository traits stay in `lib/repositories` so service logic remains testable
without a database.

## Hot State

Several domains have `hot` command groups. Hot state keeps a runtime copy of
frequently accessed data in memory, then saves it back to durable storage when
requested. This is useful for player state that changes often during a session.

Typical hot-state flow:

```text
actor:hot:init
actor:hot:get
actor:hot:override
actor:hot:save
actor:hot:remove
```

Use hot state for session workflows. Use normal domain commands for direct
durable CRUD operations.

## Transport Layer

The transport layer exists because Arma extension calls have practical payload
size limits. It provides chunked request and response handling while still
routing to the same domain command groups.

Common direct command:

```sqf
"forge_server" callExtension ["status", []];
```

Common transport path:

```text
server addon fnc_extCall
  -> transport:request:append
  -> transport:invoke_stored
  -> transport:response:get
```

## Configuration

The server extension reads `config.toml` next to the extension DLL. The current
persistence section is:

```toml
[surreal]
endpoint = "127.0.0.1:8000"
namespace = "forge"
database = "main"
username = "root"
password = "root"
connect_timeout_ms = 5000
```

`config.toml` is a launch prerequisite for server owners and developers. The
file must exist beside `forge_server_x64.dll`, and SurrealDB must already be
running at the configured endpoint before starting a Forge-enabled dedicated
server or local multiplayer test. Clients and mission designers do not run this
configuration unless they are hosting locally, but the server they connect to
must have it in place.

For install links and role-based setup guidance, see
[SurrealDB Setup](./surrealdb-setup.md).

Check persistence readiness before issuing commands that require storage:

```sqf
"forge_server" callExtension ["status", []];
"forge_server" callExtension ["surreal:status", []];
```
