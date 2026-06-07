# Forge SurrealDB

Forge uses SurrealDB as the durable database for the server extension. The
Forge Host app installs, updates, starts, and stops the local SurrealDB process.

Use the SurrealDB view in Forge Host to:

- Install or update the SurrealDB CLI.
- Start the local RocksDB-backed database.
- Configure the database bind address, root credentials, and database path.

The default local launch arguments are:

```bash
surreal start --user root --pass root --bind 127.0.0.1:8000 rocksdb://forge.db
```

The default database files are created under this directory as `forge.db`.

Forge's shared `config.toml` should match the local SurrealDB server:

```toml
[surreal]
endpoint = "127.0.0.1:8000"
namespace = "forge"
database = "main"
username = "root"
password = "root"
connect_timeout_ms = 5000
```

`root`/`root` is only the local development default. For a public or shared
server, set a real password and keep `config.toml` aligned.
