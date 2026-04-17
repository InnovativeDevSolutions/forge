# Forge Server Garage

## Overview
The garage addon is the server-side bridge for player vehicle storage and
owner-scoped vehicle unlock storage.

Garage hot state is owned by the extension. SQF validates Arma-facing requests,
serializes vehicle payloads, sends client syncs, and marks editor-placed garage
objects.

## Dependencies
- `forge_server_main`
- `forge_server_common`
- `forge_server_extension` at runtime for garage extension calls
- `forge_client_garage` for response RPCs

## Main Components
- `fnc_initGarage.sqf` initializes garage world objects.
- `fnc_initGarageStore.sqf` manages player garage hot state.
- `fnc_initVGStore.sqf` manages owner-scoped vehicle unlock state.

## Supported Operations
- initialize player garage data
- save player and owner-scoped garage state
- store and retrieve player vehicles
- initialize and save owner-scoped vehicle storage

## Runtime Notes
`forge_server_main_fnc_saveHotState` saves both `GarageStore` and
`VGarageStore` on disconnect and mission shutdown.

Garage listens for sync events through the event bus:
- `garage.vgarage.sync.requested` - updates client vehicles and unlock state when granted by store/task checkout
- `notification.requested` - storage and vehicle modification alerts

The store module emits these events when granting vehicles; garage applies the changes to player state.
