# Forge Client CAD

## Overview
The CAD addon provides the client map and dispatch interface for task
assignment, dispatch orders, support requests, group status, group roles, and
task acknowledge/decline actions.

## Dependencies
- `forge_client_main`
- server CAD events from `forge_server_cad`
- server task catalog data exposed through CAD hydrate payloads

## Main Components
- `fnc_initRepository.sqf` caches hydrated CAD view state.
- `fnc_initUI.sqf` wires the native map, top bar, bottom bar, side panel, and
  dispatcher browser controls.
- `fnc_initUIBridge.sqf` sends browser actions to server CAD RPCs and pushes
  state back to the UI.
- `fnc_handleUIEvents.sqf` handles `cad::*` browser events.
- `fnc_openUI.sqf` opens the CAD display.

## Supported Actions
- hydrate CAD state
- assign active tasks to groups
- create and close dispatch orders
- submit and close support requests
- acknowledge or decline assigned tasks
- update group status, role, and profile
- focus map requests and toggle panels

## Notes
CAD task visibility depends on server-side task catalog entries. Tasks created
through Forge task modules or `forge_server_task_fnc_startTask` are the normal
CAD-compatible task sources.

See [MAP_README.md](./MAP_README.md) for details on the integrated native map
and browser layout.
