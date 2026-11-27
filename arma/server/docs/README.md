# Forge Server Extension

Forge Server is an arma-rs extension for Arma 3 server-side persistence and
domain services. It exposes game-facing commands and stores durable state in
forge-webapi, a standalone Rust HTTP API backed by SurrealDB.

## Architecture

SQF modules call `forge_server` through `fnc_extCall`. Small requests use the
direct `callExtension` path, while large payloads are staged through the
transport layer.

```text
SQF module
  -> extension bridge
  -> domain command
  -> service layer
  -> repository
  -> forge-webapi (HTTP)
```

## Configuration

Copy `config.example.toml` to `config.toml` next to the extension DLL before
launching a Forge-enabled server. forge-webapi must also be running before the
server starts, and `base_url` must point at it.

```toml
[api]
base_url = "http://127.0.0.1:8080"
timeout_ms = 5000
```

Players and mission designers do not need this file unless they are hosting
locally. Server owners and developers do.

For install links and Forge-specific setup steps, see
[forge-webapi Setup](../../../docs/forge-webapi-setup.md).

## References

- [API Reference](./api-reference.md)
- [Usage Examples](./usage-examples.md)
- [ICOM Usage Guide](../../../docs/ICOM_USAGE_GUIDE.md)
- [Framework Module Guides](../../../docs/README.md)
