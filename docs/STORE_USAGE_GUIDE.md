# Store Usage Guide

The store module processes checkout requests. It charges a payment source and
grants purchased items to the player locker, virtual arsenal locker, and
virtual garage unlocks.

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
  ]
}
```

Rules validated by the Rust service:

- `requesterUid` is required.
- At least one item or vehicle is required.
- The checkout total must be greater than zero.
- Item categories must be `item`, `attachment`, `weapon`, `magazine`, or
  `backpack`.
- Vehicle categories must be `cars`, `armor`, `helis`, `planes`, `naval`, or
  `other`.
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
  "chargedTotal": 2000.0,
  "paymentMethod": "bank",
  "message": "Checkout completed. $2,000 charged, 1 locker grant(s), 1 vehicle unlock(s).",
  "lockerGranted": [],
  "vehicleGranted": [],
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
    ["vehicles", []]
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
    ["vehicles", [_vehicle]]
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
