# Forge Architecture

## Runtime Flow

```mermaid
flowchart TD
    Client[Arma Client Addons] --> Server[Arma Server Addons]
    Server --> Bridge[Extension Bridge]
    Bridge --> Extension[Rust arma-rs Extension]
    Extension --> Services[Service Layer]
    Services --> Repositories[Repository Traits]
    Repositories --> Api[forge-webapi HTTP API]
    Api --> Surreal[(SurrealDB)]
```

## Persistence Startup

```mermaid
sequenceDiagram
    participant Arma as Arma Server
    participant Ext as Forge Extension
    participant Api as forge-webapi

    Arma->>Ext: init (load config.toml [api])
    Arma->>Ext: status
    Ext->>Api: GET /health
    Api-->>Ext: {status, database}
    Ext-->>Arma: connected (database: connected)
```

## Data Access

```mermaid
sequenceDiagram
    participant SQF as SQF Addon
    participant Ext as Extension Command
    participant Service as Service
    participant Repo as Repository
    participant Api as forge-webapi

    SQF->>Ext: domain command
    Ext->>Service: validate and execute
    Service->>Repo: repository call
    Repo->>Api: HTTP GET/POST/PUT/DELETE
    Api-->>Repo: JSON result
    Repo-->>Service: domain model
    Service-->>Ext: response
    Ext-->>SQF: serialized result
```
