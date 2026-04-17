# Module Reference

This reference lists the main Forge modules and where each layer lives.

## Directory Map

```text
arma/client/addons/      Client-side Arma addons and browser UIs
arma/server/addons/      Server-side Arma addons and extension bridge
arma/server/extension/   Rust arma-rs extension and SurrealDB adapters
bin/icom/                Interprocess communication helper
lib/models/              Shared domain data models
lib/repositories/        Repository traits and in-memory stores
lib/services/            Domain services and workflow logic
lib/shared/              Cross-crate helpers
tools/                   Web UI build tooling
docs/                    Framework-level documentation
```

## Gameplay Domains

| Domain | Purpose | Client addon | Server addon | Service/model layer | Extension group |
| --- | --- | --- | --- | --- | --- |
| Actor | Player identity, loadout, position, status, contact identifiers, and persistent character data. | `arma/client/addons/actor` | `arma/server/addons/actor` | `lib/models/src/actor.rs`, `lib/services/src/actor.rs` | `actor:*` |
| Bank | Player accounts, cash/bank balances, PIN validation, transfers, checkout charging, and transaction context. | `arma/client/addons/bank` | `arma/server/addons/bank` | `lib/models/src/bank.rs`, `lib/services/src/bank.rs` | `bank:*`, `bank:hot:*` |
| CAD | Dispatch requests, assignments, orders, activity stream, profiles, groups, and hydrated dispatcher views. | `arma/client/addons/cad` | `arma/server/addons/cad` | `lib/models/src/cad.rs`, `lib/services/src/cad.rs` | `cad:*` |
| Garage | Player vehicle storage with plate IDs, fuel, damage, and hit point state. | `arma/client/addons/garage` | `arma/server/addons/garage` | `lib/models/src/garage.rs`, `lib/services/src/garage.rs` | `garage:*`, `garage:hot:*` |
| Locker | Player item storage keyed by classname with category and amount. | `arma/client/addons/locker` | `arma/server/addons/locker` | `lib/models/src/locker.rs`, `lib/services/src/locker.rs` | `locker:*`, `locker:hot:*` |
| Organization | Player organizations, membership, treasury, credit lines, shared assets, and fleet data. | `arma/client/addons/org` | `arma/server/addons/org` | `lib/models/src/org.rs`, `lib/services/src/org.rs` | `org:*`, `org:hot:*` |
| Phone | Contacts, messages, and email state. | `arma/client/addons/phone` | `arma/server/addons/phone` | `lib/models/src/phone.rs`, `lib/services/src/phone.rs` | `phone:*` |
| Store | Storefront entity setup, catalog hydration, checkout workflows, and checkout charging integration. | `arma/client/addons/store` | `arma/server/addons/store` | `lib/models/src/store.rs`, `lib/services/src/store.rs` | `store:checkout` |
| Task | Server-owned mission/task flows, catalog, ownership, status, participant tracking, rewards, and defuse counters. | none | `arma/server/addons/task` | `lib/models/src/task.rs`, `lib/services/src/task.rs` | `task:*` |
| Owned Garage | Organization or owner-scoped vehicle unlock storage. | via garage/org UI | server extension only | `lib/models/src/v_garage.rs`, `lib/services/src/v_garage.rs` | `owned:garage:*` |
| Owned Locker | Organization or owner-scoped arsenal unlock storage. | via locker/org UI | server extension only | `lib/models/src/v_locker.rs`, `lib/services/src/v_locker.rs` | `owned:locker:*` |

Server and extension guides:
[Actor](./ACTOR_USAGE_GUIDE.md),
[Bank](./BANK_USAGE_GUIDE.md),
[CAD](./CAD_USAGE_GUIDE.md),
[Economy](./ECONOMY_USAGE_GUIDE.md),
[Garage](./GARAGE_USAGE_GUIDE.md),
[Locker](./LOCKER_USAGE_GUIDE.md),
[Organization](./ORG_USAGE_GUIDE.md),
[Owned Storage](./OWNED_STORAGE_USAGE_GUIDE.md),
[Phone](./PHONE_USAGE_GUIDE.md),
[Store](./STORE_USAGE_GUIDE.md),
[Task](./TASK_USAGE_GUIDE.md).

Client guides:
[Client Overview](./CLIENT_USAGE_GUIDE.md),
[Main](./CLIENT_MAIN_USAGE_GUIDE.md),
[Common](./CLIENT_COMMON_USAGE_GUIDE.md),
[Actor](./CLIENT_ACTOR_USAGE_GUIDE.md),
[Bank](./CLIENT_BANK_USAGE_GUIDE.md),
[CAD](./CLIENT_CAD_USAGE_GUIDE.md),
[Garage](./CLIENT_GARAGE_USAGE_GUIDE.md),
[Locker](./CLIENT_LOCKER_USAGE_GUIDE.md),
[Notifications](./CLIENT_NOTIFICATIONS_USAGE_GUIDE.md),
[Organization](./CLIENT_ORG_USAGE_GUIDE.md),
[Phone](./CLIENT_PHONE_USAGE_GUIDE.md),
[Store](./CLIENT_STORE_USAGE_GUIDE.md).

## Infrastructure Modules

| Module | Purpose | Location |
| --- | --- | --- |
| `common` | Shared SQF helpers, base stores, utility functions, and shared UI bridge pieces. | `arma/client/addons/common`, `arma/server/addons/common` |
| `extension` | Server SQF bridge around `forge_server` extension calls and chunked transport. | `arma/server/addons/extension` |
| `main` | Mod-level configuration, pre-init wiring, and server/client startup glue. | `arma/client/addons/main`, `arma/server/addons/main` |
| `economy` | Server-side fuel, medical, and service economy helpers. Fuel and repair charge organization hot state; medical charges player bank/cash first, then organization funds with repayable member debt when personal funds cannot cover the bill. | `arma/server/addons/economy` |
| `notifications` | Client notification UI, sounds, and UI event handling. | `arma/client/addons/notifications` |
| `icom` | Rust helper for interprocess communication and event broadcasting. | `bin/icom`, `arma/server/extension/src/icom.rs` |
| `terrain` | Extension-side terrain export helper. | `arma/server/extension/src/terrain.rs` |
| `transport` | Chunked request/response handling for large extension payloads. | `arma/server/extension/src/transport.rs` |
| `surreal` | SurrealDB connection lifecycle and status reporting. | `arma/server/extension/src/surreal.rs` |

## Extension Command Groups

Commands are invoked with:

```sqf
"forge_server" callExtension ["group:command", [_arg1, _arg2]];
```

Nested groups use additional `:` separators, for example
`bank:hot:deposit`.

### Core

| Command | Purpose |
| --- | --- |
| `version` | Return the extension version string. |
| `status` | Return SurrealDB connection state. |
| `surreal:status` | Return SurrealDB connection state directly from the Surreal module. |

### Actor

| Command | Purpose |
| --- | --- |
| `actor:get` | Fetch actor data for a resolved player UID. |
| `actor:create` | Create actor data from JSON. |
| `actor:update` | Apply actor JSON updates. |
| `actor:exists` | Return `true` or `false`. |
| `actor:delete` | Delete actor data. |
| `actor:hot:init`, `actor:hot:get`, `actor:hot:keys`, `actor:hot:override`, `actor:hot:save`, `actor:hot:remove` | Manage actor hot state. |

See [Actor Usage Guide](./ACTOR_USAGE_GUIDE.md) for examples.

### Bank

| Command | Purpose |
| --- | --- |
| `bank:get`, `bank:create`, `bank:update`, `bank:exists`, `bank:delete` | Durable bank CRUD. |
| `bank:hot:init`, `bank:hot:get`, `bank:hot:override`, `bank:hot:patch`, `bank:hot:save`, `bank:hot:remove` | Manage bank hot state. |
| `bank:hot:deposit`, `bank:hot:withdraw`, `bank:hot:deposit_earnings`, `bank:hot:transfer` | Mutate hot bank balances with operation context. |
| `bank:hot:charge_checkout` | Charge a checkout against hot bank state. |
| `bank:hot:validate_pin` | Validate a PIN for bank operations. |

See [Bank Usage Guide](./BANK_USAGE_GUIDE.md) for examples.

### Garage

| Command | Purpose |
| --- | --- |
| `garage:create`, `garage:get`, `garage:add`, `garage:update`, `garage:patch`, `garage:remove`, `garage:delete`, `garage:exists` | Durable player garage operations. |
| `garage:hot:init`, `garage:hot:get`, `garage:hot:override`, `garage:hot:add`, `garage:hot:remove_vehicle`, `garage:hot:save`, `garage:hot:remove` | Manage player garage hot state. |

See [Garage Usage Guide](./GARAGE_USAGE_GUIDE.md) for examples.

### Locker

| Command | Purpose |
| --- | --- |
| `locker:create`, `locker:get`, `locker:add`, `locker:update`, `locker:patch`, `locker:remove`, `locker:delete`, `locker:exists` | Durable player locker operations. |
| `locker:hot:init`, `locker:hot:get`, `locker:hot:override`, `locker:hot:save`, `locker:hot:remove` | Manage player locker hot state. |

See [Locker Usage Guide](./LOCKER_USAGE_GUIDE.md) for examples.

### Organization

| Command | Purpose |
| --- | --- |
| `org:get`, `org:create`, `org:update`, `org:exists`, `org:delete` | Durable organization CRUD. |
| `org:assets:get`, `org:assets:update` | Manage organization assets. |
| `org:fleet:get`, `org:fleet:update` | Manage organization fleet entries. |
| `org:members:get`, `org:members:add`, `org:members:remove` | Manage organization membership. |
| `org:hot:*` | Runtime organization workflows including registration, invites, credit lines, checkout charging, assets, fleet, leave, disband, save, and remove. |

See [Org Usage Guide](./ORG_USAGE_GUIDE.md) for examples.

### Phone

| Command | Purpose |
| --- | --- |
| `phone:init` | Initialize phone state for a UID. |
| `phone:contacts:list`, `phone:contacts:add`, `phone:contacts:remove` | Manage contacts. |
| `phone:messages:list`, `phone:messages:thread`, `phone:messages:send`, `phone:messages:mark_read`, `phone:messages:delete` | Manage messages. |
| `phone:emails:list`, `phone:emails:send`, `phone:emails:mark_read`, `phone:emails:delete` | Manage emails. |
| `phone:remove` | Remove phone state for a UID. |

See [Phone Usage Guide](./PHONE_USAGE_GUIDE.md) for examples.

### CAD

| Command Group | Purpose |
| --- | --- |
| `cad:activity:append`, `cad:activity:recent` | Append and read recent activity. |
| `cad:assignments:list`, `cad:assignments:assign`, `cad:assignments:acknowledge`, `cad:assignments:decline`, `cad:assignments:upsert`, `cad:assignments:delete` | Manage dispatch assignments. |
| `cad:orders:list`, `cad:orders:create`, `cad:orders:create_from_context`, `cad:orders:close`, `cad:orders:upsert`, `cad:orders:delete` | Manage orders. |
| `cad:requests:list`, `cad:requests:submit`, `cad:requests:submit_from_context`, `cad:requests:close`, `cad:requests:upsert`, `cad:requests:delete` | Manage requests. |
| `cad:profiles:list`, `cad:profiles:update_from_context`, `cad:profiles:upsert`, `cad:profiles:delete` | Manage profiles. |
| `cad:groups:build` | Build grouped CAD state. |
| `cad:view:hydrate` | Build the dispatcher view model. |

See [CAD Usage Guide](./CAD_USAGE_GUIDE.md) for examples.

### Task

| Command Group | Purpose |
| --- | --- |
| `task:reset` | Reset task state. |
| `task:catalog:active`, `task:catalog:get`, `task:catalog:upsert`, `task:catalog:delete` | Manage task catalog entries. |
| `task:ownership:bind`, `task:ownership:release`, `task:ownership:accept`, `task:ownership:reward_context` | Manage task ownership and rewards. |
| `task:status:set`, `task:status:get`, `task:status:clear` | Manage task status. |
| `task:defuse:increment`, `task:defuse:get` | Manage defuse counters. |
| `task:clear` | Clear task state. |

See [Task Usage Guide](./TASK_USAGE_GUIDE.md) for examples.

### Owned Storage

| Command Group | Purpose |
| --- | --- |
| `owned:garage:create`, `owned:garage:fetch`, `owned:garage:get`, `owned:garage:add`, `owned:garage:remove`, `owned:garage:delete`, `owned:garage:exists` | Owner-scoped vehicle storage. |
| `owned:garage:hot:*` | Owner-scoped vehicle hot state. |
| `owned:locker:create`, `owned:locker:fetch`, `owned:locker:get`, `owned:locker:add`, `owned:locker:remove`, `owned:locker:delete`, `owned:locker:exists` | Owner-scoped item storage. |
| `owned:locker:hot:*` | Owner-scoped item hot state. |

See [Owned Storage Usage Guide](./OWNED_STORAGE_USAGE_GUIDE.md) for examples.

### Other Extension Groups

| Command Group | Purpose |
| --- | --- |
| `store:checkout` | Run store checkout behavior. |
| `icom:connect`, `icom:broadcast`, `icom:send_event` | ICom connection and event forwarding. |
| `terrain:exportSVG` | Export terrain data as SVG. |
| `transport:invoke`, `transport:invoke_stored` | Invoke commands through transport. |
| `transport:request:append`, `transport:request:clear` | Manage stored request chunks. |
| `transport:response:get`, `transport:response:clear` | Manage stored response chunks. |

## Rust Crates

| Crate | Role |
| --- | --- |
| `forge-models` | Domain models and validation. Keep these serializable and free of persistence details. |
| `forge-repositories` | Repository traits and in-memory implementations. Keep these storage-agnostic. |
| `forge-services` | Business rules and workflows. Depend on repository traits, not concrete databases. |
| `forge-shared` | Cross-crate helpers. Keep dependencies light. |
| `forge-server` | Arma extension crate. Owns command registration, SurrealDB runtime wiring, and concrete storage adapters. |
| `forge-icom` | ICom helper binary and client library. |
