# forge-webapi Setup

Forge stores durable data through **forge-webapi**, a standalone Rust HTTP API
(axum) backed by SurrealDB. The Arma server extension (`forge_server_x64.dll`)
keeps live player state in memory and writes it to the API over HTTP. It never
talks to SurrealDB directly, so setup comes down to running the API stack and
pointing the extension's `config.toml` at it.

```text
Arma 3 server ──HTTP──▶ forge-webapi (8080) ──▶ SurrealDB (8000, localhost only)
```

## Launch Requirement

Before launching an Arma server or local multiplayer test with Forge enabled:

1. Start forge-webapi and confirm `GET /health` reports the database as
   connected.
2. Create the extension's `config.toml` beside `forge_server_x64.dll` (copy
   `arma/server/extension/config.example.toml`), or use the shared repo-root
   `config.toml` from `bin/host/config.example.toml` when Forge Host is used.
3. Make sure its `[api] base_url` points at the running API.

Server owners and developers must do this before starting the dedicated server
or hosting a test session. Mission designers and players do not need their own
API unless they are running the server locally, but the server they connect to
must have forge-webapi running and configured.

If the API is down, or `config.toml` points at the wrong address,
persistence-backed systems (actors, bank accounts, garages, lockers,
organizations and phone data) will not load or save. Tasks and CAD contracts
are per-mission and kept in memory, so they do not need the API.

## Run forge-webapi

forge-webapi lives in its own repository and ships one `docker compose` file per
community. It starts the API and its SurrealDB on an internal network; SurrealDB
is bound to `127.0.0.1` only and the API on port 8080 is the only public
surface.

```powershell
cd webapi-main
Copy-Item .env.example .env   # then set a long random SURREAL_PASSWORD
docker compose up --build
```

Check it is up:

```powershell
curl http://127.0.0.1:8080/health
# {"status":"ok","database":"connected"}
```

The API refuses to start without `SURREAL_PASSWORD`; there are no default
credentials. On first boot it defines its tables itself, so a fresh database
needs no migration step. The full variable list (`FORGE_API_BIND`,
`SURREAL_ENDPOINT`, `SURREAL_NAMESPACE`, `SURREAL_DATABASE`, `SURREAL_USER`,
`SURREAL_PASSWORD`) is in the forge-webapi README.

To run the API without Docker, start a SurrealDB yourself and run
`cargo run -p forge-api` with the same environment variables set.

## Configure the Extension

Copy `arma/server/extension/config.example.toml` next to
`forge_server_x64.dll` as `config.toml`:

```toml
[api]
base_url = "http://127.0.0.1:8080"
timeout_ms = 5000
```

Missing fields fall back to these defaults. An old `[surreal]` section from an
earlier Forge version is ignored.

After launching the Arma server, verify the connection:

```sqf
"forge_server" callExtension ["status", []];
"forge_server" callExtension ["api:status", []];
"forge_server" callExtension ["persistence:pending", []]; // queued writes
```

## Inspecting Data

Mission designers and community managers who need to look at or adjust stored
data can either call the API's HTTP endpoints (for example
`GET /players/{uid}/bank`) or connect
[Surrealist Desktop](https://surrealdb.com/docs/surrealist/installation) to the
stack's SurrealDB at `http://127.0.0.1:8000` on the API host, using the
namespace, database and credentials from forge-webapi's `.env`. Edit records
only while no Arma server holds that player's hot state, or the next save will
overwrite the change.

## When Player Data Is Saved

Gameplay changes (actor, bank, locker, virtual arsenal, garages, organization)
update the extension's in-memory hot state first. They are written to
forge-webapi by `forge_server_main_fnc_saveHotState` at these points:

| When | What is saved |
| --- | --- |
| Autosave | Every connected player, every `forge_server_main_autosaveInterval` minutes (CBA server setting, default 5, 0 = off). |
| Player disconnects | That player, with position and loadout taken from the unit they controlled (`HandleDisconnect`). |
| Server redirect | The redirected players; `forge_server_main_fnc_redirectPlayers` waits up to `forge_server_main_flushTimeout` ms for the writes before sending them on. |
| Mission end or server shutdown | Every known player, once (`Ended` / `MPEnded`); the server then waits up to `forge_server_main_flushTimeout` ms (default 10000) for the writes to finish. |

API writes run in the background. If the Arma server crashes, changes since the
last autosave are lost; data already written survives in forge-webapi. To force
a save from server code:

```sqf
[_uid] call forge_server_main_fnc_saveHotState;              // one player
["", objNull, true] call forge_server_main_fnc_saveHotState; // everyone, and wait for the writes
```
