# Forge Server Main

## Overview
The main addon owns server-side bootstrap behavior for Forge. It prepares
functions, wires extension callbacks and ICom events, initializes shared stores,
and flushes hot state when players disconnect or the mission ends.

## Dependencies
- `cba_main`
- `ace_main`

## Main Components
- `fnc_initStores.sqf` initializes core server stores in dependency order.
- `fnc_saveHotState.sqf` snapshots and saves extension-backed hot state.
- `fnc_initValidationHarness.sqf` provides targeted runtime smoke checks for
  multi-module flows.
- `XEH_preInit.sqf` registers ICom and extension callback handlers.
- `XEH_postInit.sqf` starts store initialization.

## Store Initialization
The main addon initializes shared base stores, actor, bank, garage, locker,
organization, store, and validation harness state. Some addons initialize their
own state in pre-init or post-init when they are intentionally independent of
the main bootstrap flow.

## Hot State Flush
On player disconnect, mission ended, and MP ended events, `saveHotState`
persists actor, bank, locker, virtual arsenal, garage, virtual garage, and
organization hot state for the relevant UID or all known UIDs.
