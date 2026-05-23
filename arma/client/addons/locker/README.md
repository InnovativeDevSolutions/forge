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

## Notes
The client repository is display/input state. The server locker addon and
extension own saved locker and virtual arsenal data.
