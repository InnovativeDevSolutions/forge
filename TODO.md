# TODO

## compat_ace: make ACE optional

ACE is currently required: `forge_server_main` and `forge_client_main` both
list `ace_main` in `requiredAddons`, and the client calls ACE functions
directly. Later, move the ACE-specific code into
`compat_ace` addons (client and server) that load only with ACE
(`skipWhenMissingDependencies = 1`, same pattern as `forge_client_compat_aio`),
give the base addons vanilla fallbacks, and drop `ace_main` from
`forge_server_main` and `forge_client_main`.

| Area | ACE use today | Vanilla fallback |
| --- | --- | --- |
| `client/addons/locker/functions/fnc_initVARepository.sqf`, actor menu `actor::open::vlocker` | `ace_arsenal_fnc_addVirtualItems`, `ace_arsenal_fnc_openBox` | `BIS_fnc_addVirtualItemCargo` (and weapon/magazine/backpack variants), `BIS_fnc_arsenal` |
| `client/addons/locker/XEH_postInit.sqf` | Hides ACE arsenal controls on `ace_arsenal_displayOpened` | Not needed |
| `client/addons/actor/XEH_preInit.sqf` | `ace_refuel_started/tick/stopped` drive economy fuel billing | Billing only with ACE refuel |
| `client/addons/actor/XEH_postInitClient.sqf` | `ace_weaponselect_fnc_putWeaponAway` on load | `action ["SwitchWeapon", player, player, -1]` |
| `server/addons/task/XEH_postInit.sqf` | `ace_explosives_defuse` counts defused IEDs | Defuse tasks need ACE or a vanilla disarm hook |
| `server/addons/task/CfgMissions.hpp` | `ACE_IED*_Range` classes in the IED pools | Move to compat config; base lists vanilla IEDs |
| Server actor starting loadout, VA starting unlocks | `ACE_EarPlugs` | Add only when ACE is loaded |
| `mod/addons/common/CfgVehicles.hpp` | `ace_dragging_*` properties | Harmless without ACE; moving is optional |

Not ACE dependencies (leave as is): the store catalog's `isAceClassName`
filter, the `AFUNC` / ACE cargo macros, and "ACE/LACE" in dispatch (a report
format).

## Forge Host: running forge-webapi and SurrealDB

Revisit what Forge Host (`bin/host`) should do now that persistence goes
through forge-webapi. Today Host still installs and runs its own local
SurrealDB (`[surrealdb]` service, installer in `src-tauri/src/main.rs`), which
nothing in Forge uses: forge-webapi runs its own SurrealDB in its
`docker compose` stack, and Host knows nothing about the API.

Options to decide between:

- **Docker only (leading option):** replace the SurrealDB service with a
  forge-webapi service. Start `docker compose up -d` and stop
  `docker compose down` in a configured forge-webapi folder (killing the
  process does not stop the containers), health from `GET /health`
  (API vs database state), logs from `docker compose logs -f api`, check that
  `.env` with `SURREAL_PASSWORD` exists without storing it, keep
  `[api] base_url` in line with the API port, and show "Docker not found"
  when `docker` is missing. Remove the SurrealDB installer.
- **Native mode as well:** Host runs SurrealDB plus `forge-api.exe` itself and
  passes the env vars. The only case where Host's SurrealDB installer stays
  useful; roughly doubles the work.
- **Leave as is:** document that Host's SurrealDB is unused.

Host already keeps config sections it does not manage, so an old
`[surrealdb]` section survives whichever way this goes.
