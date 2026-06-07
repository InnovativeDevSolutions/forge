# Forge

Forge is a framework for Arma 3 persistent game servers. It combines SQF
addons, a Rust `arma-rs` extension, shared service crates, and web-based client
interfaces for player data, organizations, banking, garages, lockers, phones,
CAD, stores, and task workflows.

## Storage

Durable persistence is backed by SurrealDB. The server extension loads schema
modules at startup and routes domain repositories through the SurrealDB client.

```toml
[surreal]
endpoint = "127.0.0.1:8000"
namespace = "forge"
database = "main"
username = "root"
password = "root"
connect_timeout_ms = 5000
```

## Workspace

```text
arma/
  mod/         Shared client/server config addon built as @forge_mod
  client/      Client-side addons and browser UIs
  server/      Server-side addons and extension crate
bin/
  host/        Tauri host control panel for SurrealDB, ICOM, and Arma server
  icom/        Interprocess communication helper
lib/
  models/      Shared domain models
  repositories/ Repository traits and in-memory test stores
  services/    Domain business logic
  shared/      Cross-crate helpers
tools/         Web UI build tooling
```

## Common Commands

```powershell
cargo test
npm run build:webui
npm run host:dev
.\build-arma.ps1
```

`.\build-arma.ps1` builds `arma/mod`, `arma/client`, and `arma/server`. Load
the resulting `@forge_mod` on both clients and servers, `@forge_client` on
clients, and `@forge_server` on the server only.

## Documentation

- [Framework Documentation](./docs/README.md)
- [Framework Architecture](./docs/FRAMEWORK_ARCHITECTURE.md)
- [Module Reference](./docs/MODULE_REFERENCE.md)
- [Development Guide](./docs/DEVELOPMENT_GUIDE.md)

## Extension Status

```sqf
"forge_server" callExtension ["status", []];
"forge_server" callExtension ["surreal:status", []];
```

Both commands report the persistence connection state.

## Host Control Panel

`bin/host` contains a Tauri control app for local Forge server hosting. It can
start and stop SurrealDB, `forge-icom.exe`, and an Arma 3 dedicated server,
edit their launch commands, and show basic TCP health plus captured logs.

```powershell
# Build ICOM first if the host config points at target/release/forge-icom.exe
cargo build --release -p forge-icom

# Run the host UI during development
npm run host:dev

# Build the packaged desktop app
npm run host:build
```

The app reads the shared `config.toml` from the repo root during development, or
from the current/executable directory in packaged use. Start from
`bin/host/config.example.toml` when you want one shared config for Forge Host,
ICOM, and the Arma extension. Saving from the Settings view writes the active
shared `config.toml`.

The shared file includes:

- `[server]` for the ICOM hub bind address.
- `[surreal]` for the Arma extension SurrealDB connection.
- `[surrealdb]`, `[icom]`, and `[arma]` for Forge Host managed processes.

Forge Host manages the two Arma dedicated server config files separately:
`server.cfg` is launched with `-config` for server rules, missions, passwords,
and admins, while `basic.cfg` is launched with `-cfg` for network tuning. The
Arma Server settings view can create either file from `bin/host/server.example.cfg`
or `bin/host/basic.example.cfg`, then open it in the built-in editor.

Component-specific examples still exist for narrow deployments:
`bin/icom/config.example.toml` contains only `[server]`, and
`arma/server/extension/config.example.toml` contains only `[surreal]`.
