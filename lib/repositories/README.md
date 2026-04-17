# Forge Repositories

This crate defines repository traits used by the service layer. It also
provides in-memory implementations for tests and transient server state.

Durable repository implementations live in the server extension because they
depend on extension configuration and the SurrealDB runtime client.

## Contents

- Actor, bank, garage, locker, org, phone, task, CAD, owned garage, and owned
  locker repository traits.
- In-memory stores for unit tests and hot-state services.

## Guidelines

- Keep traits storage-agnostic.
- Return domain models instead of raw database records.
- Keep serialization and database-specific mapping in concrete implementations.
- Prefer focused in-memory tests for service behavior.
