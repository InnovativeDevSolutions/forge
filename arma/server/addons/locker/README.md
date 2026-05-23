# Forge Server Locker

## Overview
The locker addon is the server-side bridge for player item storage and
owner-scoped arsenal unlock storage.

Locker hot state is owned by the extension. SQF handles client events, payload
validation, synchronization, and save calls.

## Dependencies
- `forge_server_main`
- `forge_server_common`
- `forge_server_extension` at runtime for locker extension calls
- `forge_client_locker` for response RPCs

## Main Components
- `fnc_initLocker.sqf` initializes locker world objects.
- `fnc_initLockerStore.sqf` manages player locker hot state.
- `fnc_initVAStore.sqf` manages owner-scoped arsenal unlock state.

## Supported Operations
- initialize player locker data
- save player and owner-scoped locker state
- override locker data from trusted server-side callers
- initialize and save owner-scoped arsenal storage

## Runtime Notes
`forge_server_main_fnc_saveHotState` saves both `LockerStore` and `VAStore` on
disconnect and mission shutdown. Store checkout and task rewards can grant
assets into organization-owned storage through the org addon.

Locker listens for sync events through the event bus:
- `locker.sync.requested` - updates client item storage when granted by store/task checkout
- `locker.va.sync.requested` - updates client arsenal unlocks when granted
- `notification.requested` - storage and item modification alerts

The store module emits these events when granting items; locker applies the changes to player state.
