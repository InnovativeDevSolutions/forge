# SurrealDB Setup

Forge uses SurrealDB for durable storage. The Rust server extension connects to
SurrealDB on startup and applies Forge schema modules automatically, so setup
comes down to running a reachable database and matching the Forge config.

## Choose the Right Path

### Developer or Server Operator

Use this path if you are building Forge, running a local test server, or
hosting the live Arma server.

Official SurrealDB resources:

- [SurrealDB install page](https://surrealdb.com/install)
- [SurrealDB CLI `start` reference](https://surrealdb.com/docs/surrealdb/cli/start)

Forge also includes helper scripts under `arma/server/surrealdb`:

```powershell
cd arma/server/surrealdb
.\UpdateMe.bat
.\RunMe.bat
```

On Linux or macOS:

```bash
cd arma/server/surrealdb
./setup.sh
./run.sh
```

Install SurrealDB with the official method for your platform:

```powershell
# Windows
iwr https://windows.surrealdb.com -useb | iex
```

```bash
# macOS
brew install surrealdb/tap/surreal
```

```bash
# Linux
curl -sSf https://install.surrealdb.com | sh
```

For Forge, start a persistent local database instead of the default in-memory
mode:

```powershell
surreal start --user root --pass root --bind 127.0.0.1:8000 rocksdb://forge.db
```

`root`/`root` is only the local development default. For a public or shared
server, set a real password and keep `config.toml` aligned.

Then copy `arma/server/extension/config.example.toml` to `config.toml` next to
`forge_server_x64.dll` and keep the values aligned with the database you
started:

```toml
[surreal]
endpoint = "127.0.0.1:8000"
namespace = "forge"
database = "main"
username = "root"
password = "root"
connect_timeout_ms = 5000
```

After that:

1. Start the Arma server with the Forge extension enabled.
2. Let the extension connect and apply the Forge schema modules.
3. Verify the connection state:

```sqf
"forge_server" callExtension ["status", []];
"forge_server" callExtension ["surreal:status", []];
```

If you change the endpoint, namespace, database, username, or password in
SurrealDB, change the same values in Forge's `config.toml`.

### Mission Designer or Community Manager/Leader

Use this path if you mostly need to inspect, query, or adjust data for a test
or live server and you are not changing Forge source code.

Official SurrealDB resources:

- [Surrealist installation](https://surrealdb.com/docs/surrealist/installation)
- [Surrealist web app](https://app.surrealdb.com)
- [Surrealist local database serving](https://surrealdb.com/docs/surrealist/concepts/local-database-serving)

Recommended approach:

1. Install **Surrealist Desktop**. It is the better fit for Forge because the
   official docs note that the web app can be limited when connecting to
   `localhost` or non-HTTPS endpoints.
2. Connect Surrealist to the same database Forge uses.
3. Use the values from the server's `config.toml`:

```text
Endpoint:   http://127.0.0.1:8000
Namespace:  forge
Database:   main
Username:   root
Password:   root
```

If you need your own local sandbox instead of connecting to an existing Forge
server, install SurrealDB first and follow the developer/server-operator path
above. Surrealist Desktop can also launch a local database for you after the
`surreal` executable is installed and available on your `PATH`.
