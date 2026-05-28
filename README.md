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
