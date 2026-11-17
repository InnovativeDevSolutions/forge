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
- `fnc_redirectPlayers.sqf` (public) sends players (a group, units, UIDs) to
  another server after saving their data; the client half is
  `forge_client_common_fnc_redirectToServer`.
- `XEH_preInit.sqf` registers ICom and extension callback handlers, including
  the ICOM `transfer_players` event (handled on the extension callback only,
  never as a client-raisable CBA event).
- `XEH_postInit.sqf` starts store initialization.

## Store Initialization
The main addon initializes shared base stores, actor, bank, garage, locker,
organization, store, and validation harness state. Some addons initialize their
own state in pre-init or post-init when they are intentionally independent of
the main bootstrap flow.

## Hot State Flush
`saveHotState [uid, unit, waitForWrites]` snapshots the actor and saves actor,
bank, locker, virtual arsenal, garage, virtual garage and organization hot
state for one UID (or every known UID with `""`). Each store's save queues its
database write in the background.

| When | What runs |
| --- | --- |
| `HandleDisconnect` | Save that player, with the actor snapshot taken from the unit they controlled (position, loadout, stance). Returns `false`, so the engine handles the unit as usual. |
| `PlayerDisconnected` | Fallback 2 s later for a player who left without a unit; skipped when `HandleDisconnect` already saved them. |
| Autosave | Every `forge_server_main_autosaveInterval` minutes (CBA server setting, default 5, 0 = off), each connected player. |
| `Ended` / `MPEnded` | Once per mission: every known UID, then waits for the database writes to finish (`persistence:flush`, up to `forge_server_main_flushTimeout` ms, default 10000). |

To force a save from server code:

```sqf
[_uid] call forge_server_main_fnc_saveHotState;            // one player
["", objNull, true] call forge_server_main_fnc_saveHotState; // everyone, and wait for the writes
```

The extension exposes `persistence:pending` (number of writes not finished)
and `persistence:flush [timeout_ms]` (`OK`, or `Error: ...` with the count
still pending).
