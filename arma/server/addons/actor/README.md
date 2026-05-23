# Forge Server Actor

## Overview
The actor addon is the server-side bridge for player identity and character
state. It keeps Arma-facing actor snapshots in SQF while durable and hot actor
state are owned by the Rust extension.

Actor records include UID, name, loadout, position, direction, stance, rank,
life state, phone number, email, organization, and holster state.

## Dependencies
- `forge_server_main`
- `forge_server_common`
- `forge_server_extension` at runtime for actor extension calls
- `forge_server_phone` for new actor welcome email and messages
- `forge_server_bank` for new actor starting bank credit
- `forge_client_actor` for response RPCs

## Main Components
- `fnc_initActorStore.sqf` initializes `ActorModel` and `ActorStore`.
- `ActorModel` provides defaults, player snapshot conversion, migration, and
  validation.
- `ActorStore` wraps extension hot-state calls and exposes event-facing actor
  operations.

## Runtime Behavior
- Missing persistent actors can be created from live player snapshots.
- Newly created actors receive a Field Commander job orientation email, two
  Field Commander text messages, and a `$2,000` starting credit in their bank
  account.
- Hot actor reads are migrated and hydrated before use.
- `saveHotState` in the main addon snapshots and saves actor state on player
  disconnect and mission end.

## Event Surface
The addon handles server events for actor init, get, set, multi-set, save, and
remove requests, then replies to the requesting player through client actor RPCs.
