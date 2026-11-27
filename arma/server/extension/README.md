# Forge Server Extension

The Forge server extension is the Rust backend for server-side game systems.
It exposes domain commands through `arma-rs`, runs a shared Tokio runtime, and
keeps player state in memory ("hot state") while saving it to
[forge-webapi](https://github.com/InnovativeDevSolutions/forge-webapi), the
standalone HTTP API that owns persistence.

The API is the only persistence backend. There is no fallback: if the API is
unreachable, saves fail and are logged instead of silently going elsewhere.

## Launch Prerequisites

Before starting the Arma server with Forge enabled:

1. Start forge-webapi (`docker compose up` in the forge-webapi repo) and check
   it with `curl http://127.0.0.1:8080/health`.
2. Create Forge's `config.toml`. Copy `config.example.toml` beside
   `forge_server_x64.dll` for an extension-only deployment, or use the shared
   repo-root config from `bin/host/config.example.toml` when Forge Host manages
   local services.
3. Point `[api] base_url` at the running API.

The extension reads configuration during startup. If the API is offline,
persistence-backed commands still answer from hot state, but nothing is saved.

## Responsibilities

- Register extension command groups for actor, bank, garage, locker, org,
  phone, store, task, dispatch, terrain, and transport systems.
- Load extension configuration from `@forge_server/config.toml`, `config.toml`
  in the working directory, or `config.toml` beside the extension DLL.
- Save hot state to forge-webapi in background persistence tasks
  (`storage/*.rs`, `api.rs`).
- Keep SQF-facing command handlers thin while service crates own domain rules.

Task, CAD and dispatch state is in memory only and resets each mission (see
`src/task.rs`).

## Configuration

```toml
[api]
# The forge-webapi base URL: the extension's only persistence backend.
base_url = "http://127.0.0.1:8080"

# Per-request timeout in milliseconds.
timeout_ms = 5000
```

Other sections, such as the shared Forge Host config's extras or a `[surreal]`
section from older builds, are ignored.

## Status

```sqf
"forge_server" callExtension ["status", []];          // forge-webapi: "connected (database: ...)" or "unavailable: ..."
"forge_server" callExtension ["api:status", []];      // same as "status"
"forge_server" callExtension ["persistence:pending", []]; // queued saves not yet written
"forge_server" callExtension ["persistence:flush", ["10000"]]; // wait (max 30 s) for queued saves
```

## Build

```powershell
cargo test -p forge-server
cargo build -p forge-server
```
