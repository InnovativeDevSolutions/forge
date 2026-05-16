# Forge Server API Reference

The Forge server extension exposes domain-oriented commands through
`callExtension`. Persistent data is stored through the configured SurrealDB
connection and schema modules.

## Core Commands

```sqf
"forge_server" callExtension ["version", []];
"forge_server" callExtension ["status", []];
"forge_server" callExtension ["surreal:status", []];
```

`status` and `surreal:status` return `initializing`, `connected`, or `failed`.

## Domain Commands

Game systems should call the domain APIs instead of raw database operations:

- `actor:*`
- `bank:*`
- `garage:*`
- `locker:*`
- `org:*`
- `phone:*`
- `store:*`
- `task:*`
- `cad:*`
- `owned:garage:*`
- `owned:locker:*`
- `transport:*`

Large request and response payloads are routed through the transport layer when
needed by `forge_server_addons_extension_fnc_extCall`.

## Module Guides

- [Actor](../../../docs/ACTOR_USAGE_GUIDE.md)
- [Bank](../../../docs/BANK_USAGE_GUIDE.md)
- [CAD](../../../docs/CAD_USAGE_GUIDE.md)
- [Economy](../../../docs/ECONOMY_USAGE_GUIDE.md)
- [Garage](../../../docs/GARAGE_USAGE_GUIDE.md)
- [Locker](../../../docs/LOCKER_USAGE_GUIDE.md)
- [Organization](../../../docs/ORG_USAGE_GUIDE.md)
- [Owned Storage](../../../docs/OWNED_STORAGE_USAGE_GUIDE.md)
- [Phone](../../../docs/PHONE_USAGE_GUIDE.md)
- [Store](../../../docs/STORE_USAGE_GUIDE.md)
- [Task](../../../docs/TASK_USAGE_GUIDE.md)
