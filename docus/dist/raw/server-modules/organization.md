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

<table>
<thead>
  <tr>
    <th>
      Command
    </th>
    
    <th>
      Arguments
    </th>
    
    <th>
      Returns
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        org:create
      </code>
    </td>
    
    <td>
      <code>
        org_id
      </code>
      
      , <code>
        org_json
      </code>
    </td>
    
    <td>
      Organization JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:get
      </code>
    </td>
    
    <td>
      <code>
        org_id
      </code>
    </td>
    
    <td>
      Organization JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:update
      </code>
    </td>
    
    <td>
      <code>
        org_id
      </code>
      
      , <code>
        patch_json
      </code>
    </td>
    
    <td>
      Updated organization JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:exists
      </code>
    </td>
    
    <td>
      <code>
        org_id
      </code>
    </td>
    
    <td>
      <code>
        true
      </code>
      
       or <code>
        false
      </code>
      
      .
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:delete
      </code>
    </td>
    
    <td>
      <code>
        org_id
      </code>
    </td>
    
    <td>
      <code>
        OK
      </code>
      
      .
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:assets:get
      </code>
    </td>
    
    <td>
      <code>
        org_id
      </code>
    </td>
    
    <td>
      Asset map JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:assets:update
      </code>
    </td>
    
    <td>
      <code>
        org_id
      </code>
      
      , <code>
        assets_json
      </code>
    </td>
    
    <td>
      Updated asset map JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:fleet:get
      </code>
    </td>
    
    <td>
      <code>
        org_id
      </code>
    </td>
    
    <td>
      Fleet map JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:fleet:update
      </code>
    </td>
    
    <td>
      <code>
        org_id
      </code>
      
      , <code>
        fleet_json
      </code>
    </td>
    
    <td>
      Updated fleet map JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:members:get
      </code>
    </td>
    
    <td>
      <code>
        org_id
      </code>
    </td>
    
    <td>
      Member array JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:members:add
      </code>
    </td>
    
    <td>
      <code>
        org_id
      </code>
      
      , <code>
        member_uid
      </code>
    </td>
    
    <td>
      <code>
        OK
      </code>
      
      .
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:members:remove
      </code>
    </td>
    
    <td>
      <code>
        org_id
      </code>
      
      , <code>
        member_uid
      </code>
    </td>
    
    <td>
      <code>
        OK
      </code>
      
      .
    </td>
  </tr>
</tbody>
</table>

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

<table>
<thead>
  <tr>
    <th>
      Command
    </th>
    
    <th>
      Arguments
    </th>
    
    <th>
      Returns
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        org:hot:init
      </code>
    </td>
    
    <td>
      <code>
        org_id
      </code>
    </td>
    
    <td>
      Hot organization JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:hot:get
      </code>
    </td>
    
    <td>
      <code>
        org_id
      </code>
    </td>
    
    <td>
      Hot organization JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:hot:override
      </code>
    </td>
    
    <td>
      <code>
        org_id
      </code>
      
      , <code>
        hot_org_json
      </code>
    </td>
    
    <td>
      Hot organization JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:hot:ensure_member
      </code>
    </td>
    
    <td>
      <code>
        context_json
      </code>
    </td>
    
    <td>
      Hot organization JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:hot:member_invites
      </code>
    </td>
    
    <td>
      <code>
        member_uid
      </code>
    </td>
    
    <td>
      Invite array JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:hot:register
      </code>
    </td>
    
    <td>
      <code>
        context_json
      </code>
    </td>
    
    <td>
      Register result JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:hot:invite_member
      </code>
    </td>
    
    <td>
      <code>
        context_json
      </code>
    </td>
    
    <td>
      Invite result JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:hot:accept_invite
      </code>
    </td>
    
    <td>
      <code>
        context_json
      </code>
    </td>
    
    <td>
      Invite decision result JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:hot:decline_invite
      </code>
    </td>
    
    <td>
      <code>
        context_json
      </code>
    </td>
    
    <td>
      Invite decision result JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:hot:assign_credit_line
      </code>
    </td>
    
    <td>
      <code>
        context_json
      </code>
    </td>
    
    <td>
      Mutation result JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:hot:repay_credit_line
      </code>
    </td>
    
    <td>
      <code>
        context_json
      </code>
    </td>
    
    <td>
      Repayment result JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:hot:charge_checkout
      </code>
    </td>
    
    <td>
      <code>
        context_json
      </code>
    </td>
    
    <td>
      Mutation result JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:hot:add_assets
      </code>
    </td>
    
    <td>
      <code>
        context_json
      </code>
      
      , <code>
        assets_json
      </code>
    </td>
    
    <td>
      Mutation result JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:hot:add_fleet
      </code>
    </td>
    
    <td>
      <code>
        context_json
      </code>
      
      , <code>
        fleet_json
      </code>
    </td>
    
    <td>
      Mutation result JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:hot:leave
      </code>
    </td>
    
    <td>
      <code>
        context_json
      </code>
    </td>
    
    <td>
      Leave result JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:hot:disband
      </code>
    </td>
    
    <td>
      <code>
        context_json
      </code>
    </td>
    
    <td>
      Disband result JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:hot:save
      </code>
    </td>
    
    <td>
      <code>
        org_id
      </code>
    </td>
    
    <td>
      Current hot organization JSON and async durable save.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:hot:remove
      </code>
    </td>
    
    <td>
      <code>
        org_id
      </code>
    </td>
    
    <td>
      <code>
        OK
      </code>
      
      .
    </td>
  </tr>
</tbody>
</table>

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
