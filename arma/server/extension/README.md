# Forge Server Extension

The Forge server extension is the Rust backend for server-side game systems.
It exposes domain commands through `arma-rs`, runs a shared Tokio runtime, and
persists durable state through SurrealDB.

This extension build targets SurrealDB `3.x`.

## Responsibilities

- Register extension command groups for actor, bank, garage, locker, org,
  phone, store, task, CAD, terrain, and transport systems.
- Load extension configuration from `@forge_server/config.toml`.
- Connect to SurrealDB and apply schema modules on startup.
- Keep SQF-facing command handlers thin while service crates own domain rules.

## Configuration

```toml
[surreal]
endpoint = "127.0.0.1:8000"
namespace = "forge"
database = "main"
username = "root"
password = "root"
connect_timeout_ms = 5000
```

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
