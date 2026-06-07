# Forge Server Extension

The Forge server extension is the Rust backend for server-side game systems.
It exposes domain commands through `arma-rs`, runs a shared Tokio runtime, and
persists durable state through SurrealDB.

This extension build targets SurrealDB `3.x`.

## Launch Prerequisites

Before starting the Arma server with Forge enabled:

1. Start SurrealDB.
2. Create Forge's `config.toml`. Copy `config.example.toml` beside
   `forge_server_x64.dll` for an extension-only deployment, or use the shared
   repo-root config from `bin/host/config.example.toml` when Forge Host manages
   local services.
3. Match the `config.toml` endpoint, namespace, database, username, and password
   to the running SurrealDB instance.

The extension reads configuration during startup. If SurrealDB is offline or
the config values do not match, persistence-backed commands are not ready for
normal gameplay.

## Responsibilities

- Register extension command groups for actor, bank, garage, locker, org,
  phone, store, task, CAD, terrain, and transport systems.
- Load extension configuration from `@forge_server/config.toml`, `config.toml`
  in the working directory, or `config.toml` beside the extension DLL.
- Connect to SurrealDB and apply schema modules on startup.
- Keep SQF-facing command handlers thin while service crates own domain rules.

## Configuration

```toml
[surreal]
# SurrealDB HTTP endpoint.
endpoint = "127.0.0.1:8000"

# Namespace and database selected after connecting.
namespace = "forge"
database = "main"

# Local development credentials.
username = "root"
password = "root"

# Initial connection timeout in milliseconds.
connect_timeout_ms = 5000
```

The extension reads only `[surreal]`. Extra sections from the shared Forge Host
config are ignored.

## Status

```sqf
"forge_server" callExtension ["status", []];
"forge_server" callExtension ["surreal:status", []];
```

Status values are `initializing`, `connected`, or `failed`.

## Build

```powershell
cargo test -p forge-server
cargo build -p forge-server
```
