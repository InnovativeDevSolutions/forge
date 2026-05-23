# Forge Shared Libraries

The `lib` workspace contains reusable Rust crates for Forge domain models,
repository traits, services, and shared helpers.

## Crates

- `forge-models`: serializable domain models shared by services and extension
  routes.
- `forge-repositories`: repository traits plus in-memory implementations used
  by tests and transient hot-state stores.
- `forge-services`: business logic for actor, bank, garage, locker, org,
  phone, store, task, and CAD workflows.
- `forge-shared`: validation and cross-crate helpers.

Durable persistence is implemented in the server extension with SurrealDB
repository implementations.

## Test

```powershell
cargo test -p forge-models
cargo test -p forge-repositories
cargo test -p forge-services
cargo test -p forge-shared
```
