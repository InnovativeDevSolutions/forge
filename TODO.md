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

Forge Host (`bin/host`) has to catch up with persistence going through
forge-webapi. Today Host still installs and runs its own local
SurrealDB (`[surrealdb]` service, installer in `src-tauri/src/main.rs`), which
nothing in Forge uses: forge-webapi runs its own SurrealDB in its
`docker compose` stack, and Host knows nothing about the API.

Decided: Host's SurrealDB portion (the `[surrealdb]` service, the installer
and version picker, the SurrealDB settings panel) can be removed, but only in
the same change that adds the forge-webapi service below, so Host is never
left without a way to run persistence. That means Docker only: Host does not
run SurrealDB or `forge-api.exe` natively.

Plan:

- Replace the SurrealDB service with a forge-webapi service pointed at a
  configured forge-webapi folder.
- Start with `docker compose up -d` and stop with `docker compose down`
  (killing the process does not stop the containers).
- Health from `GET /health`, showing API and database state separately.
- Logs from `docker compose logs -f api` in the log panel.
- Check that `.env` with `SURREAL_PASSWORD` exists, without storing it.
- Keep `[api] base_url` in line with the API port.
- Show "Docker not found" when `docker` is missing.
- Remove the SurrealDB installer, version picker and settings panel.
- An old `[surrealdb]` section in existing configs is kept (and ignored),
  since Host keeps sections it does not manage.

### Alternative: embedded API and database (no Docker)

Instead of (or alongside) Docker, Host could run forge-webapi with SurrealDB
embedded, so Host needs neither Docker nor `surreal.exe`. If this is chosen,
it changes the "Docker only" decision above; Docker stays the recommended
production setup.

- forge-webapi: switch `crates/forge-api/src/db.rs` from the HTTP-only engine
  (`Surreal<Client>`) to `engine::any`, so the address picks the engine:
  `http://surrealdb:8000` keeps the compose setup, `surrealkv://<folder>`
  stores data in a local folder (pure Rust, builds on Windows without the C
  toolchain RocksDB needs). Enable the `kv-surrealkv` feature.
- forge-webapi: split `forge-api` into a library (`serve(config)`) plus the
  existing binary.
- Host, preferred: launch `forge-api.exe` as a bundled sidecar process (like
  ICOM), so an API crash cannot take down the Host window and the binary also
  runs on its own. Alternative: call `serve` in-process on Tauri's async
  runtime (simpler, but the API stops whenever Host closes or crashes).
- Health from `/health`; data folder set in Host settings.

Trade-offs: only one process can open the data folder, so Surrealist cannot
connect while the API runs (inspect through the API, or stop it first);
noticeably longer compile time and a larger binary; two deployment modes to
test.
