# Forge SurrealDB

Forge uses SurrealDB as the durable database for the server extension. These
helpers install the SurrealDB CLI and start a local RocksDB-backed Forge
database from this directory.

These scripts are for local development and single-host Forge servers. For a
public or shared production host, change the root password and review bind,
firewall, TLS, backup, and upgrade policy before exposing the database.

## Windows

Install or update SurrealDB:

```bat
UpdateMe.bat
```

If this is the first install and the terminal cannot find `surreal` after the
script finishes, open a new terminal so Windows reloads `PATH`.

Start Forge's local database:

```bat
RunMe.bat
```

Install and start in one step:

```bat
AllInOne.bat
```

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
