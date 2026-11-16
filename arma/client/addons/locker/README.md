# Forge Client Locker

## Overview
The locker addon manages client repositories for personal locker state and
virtual arsenal unlock state. It also integrates with ACE Arsenal display
behavior.

## Dependencies
- `forge_client_main`
- ACE Arsenal
- server locker events from `forge_server_locker`

## Main Components
- `fnc_initRepository.sqf` manages locker state, container open/close behavior,
  and server sync requests.
- `fnc_initVARepository.sqf` manages virtual arsenal state.

## Runtime Behavior
- Requests locker and virtual arsenal state after actor load.
- Syncs server responses into client repositories.
- Sends locker override data to the server when a managed locker container is
  closed.
- Hides selected ACE Arsenal controls when the arsenal display opens.

## Extension Points
Compat addons can take over a locker's fill/save cycle without patching this
addon:

- `forge_client_locker_lockersCreated [lockers]` (local CBA event) is raised
  once the local locker boxes exist. The array is also kept as
  `forge_client_locker_LockerRepository get "localLockers"`.
- `forge_client_locker_synced []` (local CBA event) is raised after each server
  sync of locker contents.
- Setting `forge_client_locker_externallyManaged = true` on a box makes the
  vanilla `ContainerOpened` / `ContainerClosed` handlers skip it.
- Repository methods: `fillContainer [box]`, `readContainer [box]` and
  `commitContainer [box, unit]` (saves to the server).

`forge_client_compat_aio` uses these to support AIO - Arma Inventory Overhaul.

## Notes
The client repository is display/input state. The server locker addon and
extension own saved locker and virtual arsenal data.
