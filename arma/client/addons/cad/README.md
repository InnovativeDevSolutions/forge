# Forge Client CAD

## Overview
The CAD addon provides the client map and dispatch interface: contracts,
group assignment, accept/decline by the group leader, and group roster, role
and status. When the server runs `forge_server_dispatch`, the same UI also
shows dispatch orders, support requests, the activity feed and generated task
requests.

## Dependencies
- `forge_client_main`
- server CAD events from `forge_server_cad`
- optional dispatch events from `forge_server_dispatch`

## Main Components
- `fnc_initRepository.sqf` caches hydrated CAD view state.
- `fnc_initUI.sqf` wires the native map, top bar, bottom bar, side panel, and
  dispatcher browser controls.
- `fnc_initUIBridge.sqf` sends browser actions to server CAD and dispatch RPCs
  and pushes state back to the UI.
- `fnc_handleUIEvents.sqf` handles `cad::*` browser events.
- `fnc_openUI.sqf` opens the CAD display.

## Supported Actions
- hydrate CAD state
- assign contracts to groups (dispatcher)
- accept or decline the assigned contract (group leader)
- update group status and role (leader or dispatcher)
- focus groups, members, contracts and requests on the map

With `forge_server_dispatch`:
- create and close dispatch orders
- submit and close support requests
- request generated mission tasks

## Dispatch gating
The hydrate payload carries `dispatchEnabled`. When it is `false` the side
panel hides the Requests and Activity tabs, and the dispatcher board hides the
order, generated task, request and activity controls.

## Notes
CAD task visibility depends on server-side task catalog entries. Tasks created
through Forge task modules or `forge_server_task_fnc_startTask` are the normal
CAD-compatible task sources. A contract that was declined shows "Declined by
<group>" until it is reassigned.

See [MAP_README.md](./MAP_README.md) for details on the integrated native map
and browser layout.
