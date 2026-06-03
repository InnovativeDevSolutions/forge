# Forge Server Store

## Overview
The store addon manages server-side storefront entities, catalog hydration, and
checkout coordination.

SQF owns Arma-facing storefront discovery and request validation. The Rust
extension owns authoritative checkout calculation through `store:checkout`.

## Dependencies
- `forge_server_main`
- `forge_server_common`
- `forge_server_extension` at runtime for checkout calls
- `forge_server_actor`, `forge_server_bank`, and `forge_server_org` at runtime
  for checkout context and payment state
- `forge_client_store` for response RPCs

## Main Components
- `fnc_initStore.sqf` marks editor-placed store objects with `isStore = true`.
- `fnc_initCatalogService.sqf` scans live Arma config categories, builds
  catalog responses, resolves checkout entries, and calculates authoritative
  catalog prices. It also applies the optional mission `CfgStore` filter and
  overrides before payloads or checkout validation use catalog entries.
- `fnc_initStorefrontStore.sqf` builds hydrate payloads, validates checkout
  requests, calls `store:checkout`, syncs client patches, and coordinates
  related bank/org persistence. Purchased units are fulfilled by spawning the
  granted unit classes at discovered `unit_spawn` markers after the backend
  charge succeeds.

## Mission Catalog Filter
Missions can include `CfgStore.hpp` from `description.ext` to control the
generated catalog without changing the addon.

```cpp
class CfgStore {
    mode = "allowlist"; // dynamic, allowlist, or denylist

    class Categories {
        primary[] = {"arifle_MX_F", "arifle_MXC_F"};
        cars[] = {"B_MRAP_01_F"};
        units[] = {"B_Soldier_F"};
    };

    class Overrides {
        class arifle_MX_F {
            price = 2500;
            displayName = "MX Rifle";
            description = "Approved PMC service rifle.";
        };
    };
};
```

`dynamic` keeps the full generated catalog. `allowlist` only shows classnames
listed for the requested category. `denylist` removes listed classnames from the
generated category. Overrides are applied server-side, so checkout validation
uses the same prices and descriptions the UI displays.

`units[]` follows the same `dynamic`, `allowlist`, and `denylist` behavior as
item and vehicle categories. Unit purchases are immediate spawn grants, not
durable virtual garage unlocks.

The filter is currently global for the mission. Revisit per-store profile
support if individual vendors need different inventories.

## Unit Spawn Markers
Purchased units spawn at mission markers named `unit_spawn`, `unit_spawn_1`,
`unit_spawn_2`, and so on. The store resolves the closest initialized store
object to the requesting player, scans `allMapMarkers` at fulfillment time, and
uses the closest matching marker within 25 meters of that store.

If no matching marker exists within 25 meters, the store falls back to spawning
units around the store object. If no store object can be resolved, it falls back
to the requesting player so checkout still completes.

## Editor Entities
`fnc_initStore` matches non-null mission namespace objects whose variable names
contain `store`, mirroring the garage entity initialization pattern.

## Checkout Flow
Store checkout can charge cash, bank balance, organization funds, or approved
credit lines depending on the hydrated session context. Checkout results can
grant locker assets, organization assets, fleet vehicles, and immediate unit
spawns through the related domain stores and Arma server runtime.

Checkout results emit notifications and syncs through the event bus:
- `notification.requested` - receipt and transaction alerts
- `bank.account.sync.requested` - player balance updates
- `org.sync.requested` - organization balance and asset updates
- `locker.sync.requested` - item grant notifications
- `garage.vgarage.sync.requested` - vehicle grant notifications
