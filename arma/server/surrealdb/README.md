# Forge Host SurrealDB Working Directory

This folder is the working directory Forge Host uses for its managed local
SurrealDB process (`[surrealdb]` in `bin/host/config.example.toml`). The
database files (`forge.db/`) are gitignored.

The Arma server extension no longer connects to SurrealDB. Durable data goes
through forge-webapi, which runs its own SurrealDB in its `docker compose`
stack. See [forge-webapi Setup](../../../docs/forge-webapi-setup.md).

Forge Host does not manage forge-webapi yet, so a SurrealDB started from this
folder is not used by Forge persistence. The extension reads only the `[api]`
section of `config.toml`.
