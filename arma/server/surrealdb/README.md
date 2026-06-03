# Forge SurrealDB

Forge uses SurrealDB as the durable database for the server extension. These
helpers install the SurrealDB CLI and start a local RocksDB-backed Forge
database from this directory.

These scripts are for local development and single-host Forge servers. For a
public or shared production host, change the root password and review bind,
firewall, TLS, backup, and upgrade policy before exposing the database.

## Windows

Install or update SurrealDB to the newest compatible SurrealDB 3.x release:

```bat
UpdateMe.bat
```

Install a specific SurrealDB release:

```bat
UpdateMe.bat v3.1.2
```

Install the latest stable SurrealDB release, including newer major versions:

```bat
UpdateMe.bat latest
```

`latest` requires confirmation because a newer SurrealDB major version can
require rebuilding the Forge server extension from source with a compatible
`surrealdb` Rust crate.

The PowerShell entry point exposes the same behavior:

```powershell
.\UpdateSurrealDB.ps1
.\UpdateSurrealDB.ps1 -Version v3.1.2
.\UpdateSurrealDB.ps1 -Version latest
```

If this is the first install and the terminal cannot find `surreal` after the
script finishes, open a new terminal so Windows reloads `PATH`.

Start Forge's local database:

```bat
RunMe.bat
```

Or start it directly with PowerShell:

```powershell
.\RunSurrealDB.ps1
```

Install and start in one step:

```bat
AllInOne.bat
```

`AllInOne.bat` also defaults to the newest compatible SurrealDB 3.x release.
Pass the same version argument as `UpdateMe.bat` to override it.

## Linux or macOS

Install SurrealDB:

```bash
./setup.sh
```

Start Forge's local database:

```bash
./run.sh
```

Update SurrealDB:

```bash
./update.sh
```

## Manual Command

The run scripts execute:

```bash
surreal start --user root --pass root --bind 127.0.0.1:8000 rocksdb://forge.db
```

The database files are created under `arma/server/surrealdb/forge.db`.

Forge's extension config should match the local SurrealDB server:

```toml
[surreal]
endpoint = "127.0.0.1:8000"
namespace = "forge"
database = "main"
username = "root"
password = "root"
connect_timeout_ms = 5000
```
