# Forge Client Actor

## Overview
The actor addon owns the player interaction menu and client-side actor
repository. It initializes actor state from the server, tracks client-visible
actor fields, and routes menu actions to other Forge UIs.

## Dependencies
- `forge_client_main`
- server actor events from `forge_server_actor`
- runtime integrations with bank, CAD, garage, org, phone, store, locker, and
  notifications addons

## Main Components
- `fnc_initRepository.sqf` manages client actor state and server init/save
  requests.
- `fnc_openUI.sqf` opens `RscActorMenu`.
- `fnc_handleUIEvents.sqf` handles browser menu actions.

## Event Surface
The actor menu can open bank, ATM mode, CAD, garage, virtual garage, org, phone,
store, and ACE arsenal interactions. Client post-init also wires player killed
and respawn handlers into the server economy flow.

## Runtime Notes
Actor state is loaded before dependent systems initialize. When the server sends
actor sync data, the repository updates local view state and clears the loading
screen.
