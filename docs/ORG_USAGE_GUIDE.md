# Organization Usage Guide

The organization module stores organization records, members, assets, fleet
entries, and credit lines. Durable commands manage persisted records directly.
Hot-state commands support the active organization UI workflows.

## Storage Model

Core organization:

```json
{
  "id": "default",
  "owner": "server",
  "name": "Default Organization",
  "funds": 0.0,
  "reputation": 0,
  "credit_lines": {}
}
```

Hot organization:

```json
{
  "id": "default",
  "owner": "server",
  "name": "Default Organization",
  "funds": 0.0,
  "reputation": 0,
  "credit_lines": {},
  "assets": {},
  "fleet": {},
  "members": {},
  "pending_invites": {}
}
```

Rules validated by the Rust service:

- `id` must be non-empty and contain only alphanumeric characters or `_`.
- `owner` must be `server` or a 17-digit Steam UID.
- `name` cannot be empty, cannot exceed 100 characters, and cannot contain
  control characters.
- `funds`, reputation, and credit line amounts cannot be negative.
- Player registration is rejected when the player already belongs to a
  non-default organization.

## Durable Commands

| Command | Arguments | Returns |
| --- | --- | --- |
| `org:create` | `org_id`, `org_json` | Organization JSON. |
| `org:get` | `org_id` | Organization JSON. |
| `org:update` | `org_id`, `patch_json` | Updated organization JSON. |
| `org:exists` | `org_id` | `true` or `false`. |
| `org:delete` | `org_id` | `OK`. |
| `org:assets:get` | `org_id` | Asset map JSON. |
| `org:assets:update` | `org_id`, `assets_json` | Updated asset map JSON. |
| `org:fleet:get` | `org_id` | Fleet map JSON. |
| `org:fleet:update` | `org_id`, `fleet_json` | Updated fleet map JSON. |
| `org:members:get` | `org_id` | Member array JSON. |
| `org:members:add` | `org_id`, `member_uid` | `OK`. |
| `org:members:remove` | `org_id`, `member_uid` | `OK`. |

## Create an Organization

The command key is authoritative for `id`.

```sqf
private _org = createHashMapFromArray [
    ["id", _orgId],
    ["owner", getPlayerUID player],
    ["name", "Spearnet Logistics"],
    ["funds", 0],
    ["reputation", 0],
    ["credit_lines", createHashMap]
];

private _result = "forge_server" callExtension ["org:create", [
    _orgId,
    toJSON _org
]];
```

## Update Organization Funds

```sqf
private _patch = createHashMapFromArray [
    ["funds", 5000],
    ["reputation", 10]
];

private _result = "forge_server" callExtension ["org:update", [
    _orgId,
    toJSON _patch
]];
```

Supported durable patch fields are `id`, `owner`, `name`, `funds`,
`reputation`, and `credit_lines`.

## Assets and Fleet

Assets are grouped by category, then classname.

```sqf
private _assets = createHashMapFromArray [
    ["ammo", createHashMapFromArray [
        ["ACE_30Rnd_65x39_caseless_mag", createHashMapFromArray [
            ["classname", "ACE_30Rnd_65x39_caseless_mag"],
            ["type", "ammo"],
            ["quantity", 20]
        ]]
    ]]
];

"forge_server" callExtension ["org:assets:update", [_orgId, toJSON _assets]];
```

Fleet is keyed by an internal fleet entry ID.

```sqf
private _fleet = createHashMapFromArray [
    ["B_Truck_01_transport_F_0", createHashMapFromArray [
        ["classname", "B_Truck_01_transport_F"],
        ["name", "Transport Truck"],
        ["type", "cars"],
        ["status", "Ready"],
        ["damage", "0%"]
    ]]
];

"forge_server" callExtension ["org:fleet:update", [_orgId, toJSON _fleet]];
```

## Hot-State Commands

| Command | Arguments | Returns |
| --- | --- | --- |
| `org:hot:init` | `org_id` | Hot organization JSON. |
| `org:hot:get` | `org_id` | Hot organization JSON. |
| `org:hot:override` | `org_id`, `hot_org_json` | Hot organization JSON. |
| `org:hot:ensure_member` | `context_json` | Hot organization JSON. |
| `org:hot:member_invites` | `member_uid` | Invite array JSON. |
| `org:hot:register` | `context_json` | Register result JSON. |
| `org:hot:invite_member` | `context_json` | Invite result JSON. |
| `org:hot:accept_invite` | `context_json` | Invite decision result JSON. |
| `org:hot:decline_invite` | `context_json` | Invite decision result JSON. |
| `org:hot:assign_credit_line` | `context_json` | Mutation result JSON. |
| `org:hot:repay_credit_line` | `context_json` | Repayment result JSON. |
| `org:hot:charge_checkout` | `context_json` | Mutation result JSON. |
| `org:hot:add_assets` | `context_json`, `assets_json` | Mutation result JSON. |
| `org:hot:add_fleet` | `context_json`, `fleet_json` | Mutation result JSON. |
| `org:hot:leave` | `context_json` | Leave result JSON. |
| `org:hot:disband` | `context_json` | Disband result JSON. |
| `org:hot:save` | `org_id` | Current hot organization JSON and async durable save. |
| `org:hot:remove` | `org_id` | `OK`. |

## Register from UI Context

```sqf
private _context = createHashMapFromArray [
    ["requesterUid", getPlayerUID player],
    ["requesterName", name player],
    ["orgId", _orgId],
    ["orgName", "Spearnet Logistics"],
    ["existingOrgId", "default"]
];

private _result = "forge_server" callExtension ["org:hot:register", [toJSON _context]];
```

## Invite and Accept

```sqf
private _invite = createHashMapFromArray [
    ["requesterUid", getPlayerUID player],
    ["requesterName", name player],
    ["orgId", _orgId],
    ["requesterIsDefaultOrgCeo", false],
    ["targetUid", _targetUid],
    ["targetName", _targetName],
    ["targetOrgId", "default"]
];

"forge_server" callExtension ["org:hot:invite_member", [toJSON _invite]];

private _decision = createHashMapFromArray [
    ["requesterUid", _targetUid],
    ["requesterName", _targetName],
    ["orgId", _orgId],
    ["existingOrgId", "default"]
];

"forge_server" callExtension ["org:hot:accept_invite", [toJSON _decision]];
```

## Credit Line Checkout

```sqf
private _credit = createHashMapFromArray [
    ["requesterUid", getPlayerUID player],
    ["orgId", _orgId],
    ["requesterIsDefaultOrgCeo", false],
    ["memberUid", _memberUid],
    ["memberName", _memberName],
    ["amount", 1000]
];

"forge_server" callExtension ["org:hot:assign_credit_line", [toJSON _credit]];

private _charge = createHashMapFromArray [
    ["requesterUid", _memberUid],
    ["orgId", _orgId],
    ["requesterIsDefaultOrgCeo", false],
    ["source", "credit_line"],
    ["amount", 250],
    ["commit", true]
];

"forge_server" callExtension ["org:hot:charge_checkout", [toJSON _charge]];
```

## Error Handling

```sqf
private _payload = _result select 0;
if (_payload find "Error:" == 0) exitWith {
    systemChat format ["Organization error: %1", _payload];
};
```
