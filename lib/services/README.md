# Forge Services

This crate owns domain behavior for Forge systems. Services depend on
repository traits, which keeps business logic testable with in-memory stores
and independent from the concrete persistence backend.

## Responsibilities

- Validate command inputs.
- Apply domain rules and mutation workflows.
- Return structured results for extension/SQF callers.
- Keep persistence details behind repository traits.

## Test

```powershell
cargo test -p forge-services
```
