# Store Usage Guide

The store module processes checkout requests. It charges a payment source and
grants purchased items to the player locker, virtual arsenal locker, and
virtual garage unlocks. Unit purchases are fulfilled as immediate server-side
spawn grants at discovered `unit_spawn` markers.

## Server SQF Module

The server addon uses two long-lived module objects:

- `StorefrontStore` is the storefront workflow facade. It builds hydrate
  payloads, validates checkout requests, calls the Rust `store:checkout`
  command, syncs UI patches, and asks related module stores to save hot state.
- `StoreCatalogService` scans configured item and vehicle categories, builds
  catalog responses, resolves checkout entries, and calculates authoritative
  prices.

Editor-placed store entities are initialized by `fnc_initStore` during store
post-init. The initializer matches non-null mission namespace objects whose
variable names contain `store` and sets `isStore = true`, following the same
pattern used by garage entities.

## Mission Catalog Filter

The store catalog is generated from loaded Arma config classes, then an
optional mission `CfgStore` filter can allow or deny classnames per category.
Include `CfgStore.hpp` from `description.ext`:

```cpp
#include "CfgStore.hpp"
```

```cpp
class CfgStore {
    mode = "allowlist"; // dynamic, allowlist, or denylist
    modMode = "dynamic"; // dynamic, allowlist, or denylist
    mods[] = {}; // ModSources child class names used when modMode is not dynamic

    class ModSources {
        class rhs {
            patches[] = {"rhs_main", "rhsusf_main"};
            addons[] = {"rhs_", "rhsusf_", "rhsgref_", "rhsafrf_"};
            prefixes[] = {"rhs_", "rhsusf_", "rhsgref_", "rhsafrf_"};
        };

        class ace3 {
            patches[] = {"ace_main"};
            addons[] = {"ace_"};
            prefixes[] = {"ace_"};
        };
    };

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
listed for each category. `denylist` removes listed classnames. Overrides are
server-side and are used by both the UI payload and checkout validation.
`units[]` uses the same filter behavior as every other category.

`modMode` applies before category filtering. `allowlist` only keeps generated
entries that match one of the configured `mods[]`; `denylist` removes matching
entries. Each `ModSources` child can define `patches[]` to detect whether the
mod is loaded, `addons[]` for config source addon/source mod names or classname
prefixes, and `prefixes[]` for classname prefixes. If a mod source defines no
patches, it is treated as available and only the source/prefix checks are used.

The current filter is global for the mission. Revisit per-store profile support
if individual vendors need different inventories.

## Unit Spawn Markers

Purchased units spawn at mission markers named `unit_spawn`, `unit_spawn_1`,
`unit_spawn_2`, and so on. The store resolves the closest initialized store
object to the requesting player, scans `allMapMarkers` when checkout fulfillment
runs, and uses the closest matching marker within 25 meters of that store.

If no matching marker exists within 25 meters, the store falls back to spawning
units around the store object. If no store object can be resolved, it falls back
to the requesting player.

## Checkout Model

`store:checkout` accepts one JSON context.

```json
{
  "requesterUid": "76561198000000000",
  "requesterName": "Player Name",
  "orgId": "default",
  "requesterIsDefaultOrgCeo": false,
  "paymentMethod": "bank",
  "items": [
    {
      "classname": "arifle_MX_F",
      "category": "weapon",
      "priceValue": 500,
      "quantity": 1
    }
  ],
  "vehicles": [
    {
      "classname": "B_Quadbike_01_F",
      "category": "cars",
      "priceValue": 1500
    }
  ],
  "units": [
    {
      "classname": "B_Soldier_F",
      "category": "units",
      "priceValue": 2500
    }
  ]
}
```

Rules validated by the Rust service:

- `requesterUid` is required.
- At least one item, vehicle, or unit is required.
- The checkout total must be greater than zero.
- Item categories must be `item`, `attachment`, `weapon`, `magazine`, or
  `backpack`.
- Vehicle categories must be `cars`, `armor`, `helis`, `planes`, `naval`, or
  `other`.
- Unit categories must be `units` or `unit`.
- Payment method must be `cash`, `bank`, `org_funds`, or `credit_line`.
- Player locker capacity cannot exceed 25 unique items after checkout.
- Organization funds can only be charged by the org owner or the default org
  CEO flag.

## Command

| Command | Arguments | Returns |
| --- | --- | --- |
| `store:checkout` | `checkout_json` | Checkout result JSON. |

## Result Model

```json
{
  "chargedTotal": 4500.0,
  "paymentMethod": "bank",
  "message": "Checkout completed. $4,500 charged, 1 locker grant(s), 1 vehicle unlock(s), 1 unit grant(s).",
  "lockerGranted": [],
  "vehicleGranted": [],
  "unitGranted": [],
  "lockerPatch": {},
  "vaPatch": {},
  "vgaragePatch": {},
  "bankPatch": {},
  "orgPatch": {},
  "orgTargetUids": []
}
```

Patch fields are intended for UI updates after checkout. The service commits
all grants and payment changes together, and attempts rollback if a later write
fails.

## Player Bank Checkout

```sqf
private _item = createHashMapFromArray [
    ["classname", "arifle_MX_F"],
    ["category", "weapon"],
    ["priceValue", 500],
    ["quantity", 1]
];

private _checkout = createHashMapFromArray [
    ["requesterUid", getPlayerUID player],
    ["requesterName", name player],
    ["orgId", "default"],
    ["requesterIsDefaultOrgCeo", false],
    ["paymentMethod", "bank"],
    ["items", [_item]],
    ["vehicles", []],
    ["units", []]
];

private _result = "forge_server" callExtension ["store:checkout", [toJSON _checkout]];
```

## Organization Funds Checkout

When `paymentMethod` is `org_funds`, vehicles are also added to the
organization fleet patch.

```sqf
private _vehicle = createHashMapFromArray [
    ["classname", "B_Quadbike_01_F"],
    ["category", "cars"],
    ["priceValue", 1500]
];

private _checkout = createHashMapFromArray [
    ["requesterUid", getPlayerUID player],
    ["requesterName", name player],
    ["orgId", _orgId],
    ["requesterIsDefaultOrgCeo", false],
    ["paymentMethod", "org_funds"],
    ["items", []],
    ["vehicles", [_vehicle]],
    ["units", []]
];

private _result = "forge_server" callExtension ["store:checkout", [toJSON _checkout]];
```

## Error Handling

```sqf
private _payload = _result select 0;
if (_payload find "Error:" == 0) exitWith {
    hint format ["Checkout failed: %1", _payload];
};

private _checkoutResult = fromJSON _payload;
```
