# Actor Usage Guide

The actor module stores persistent player character data: identity, loadout,
position, direction, stance, contact fields, state, holster status, rank, and
organization.

## Storage Model

Actor data is persisted through SurrealDB by the server extension.

```json
{
  "uid": "76561198000000000",
  "name": "Player Name",
  "loadout": {},
  "position": [1234.5, 6789.0, 0.0],
  "direction": 90.0,
  "stance": "STAND",
  "email": "0160000000@spearnet.mil",
  "phone_number": "0160000000",
  "state": "HEALTHY",
  "holster": true,
  "rank": null,
  "organization": "default"
}
```

Rules validated by the Rust service:

- `uid` is authoritative from the command argument and must be a 17-digit Steam
UID.
- `name` is optional, but cannot be empty when set and cannot exceed 50
characters.
- `position` must be three finite numbers when set.
- `direction` must be in the `0.0 <= direction < 360.0` range.
- `email` must contain `@` and end with `.mil` when set.
- `phone_number` must start with `0160` and be 10 digits when set.
- Empty `phone_number`, `email`, or `organization` fields are filled on create.

## Commands

All commands are called on the `actor` group.

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
        actor:get
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      Actor JSON. If no actor exists, returns a default actor but does not persist it.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        actor:create
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        actor_json
      </code>
    </td>
    
    <td>
      Persisted actor JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        actor:update
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        patch_json
      </code>
    </td>
    
    <td>
      Updated actor JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        actor:exists
      </code>
    </td>
    
    <td>
      <code>
        uid
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
        actor:delete
      </code>
    </td>
    
    <td>
      <code>
        uid
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

## Create an Actor

The `uid` field in the JSON is overwritten with the command UID.

```sqf
private _actor = createHashMapFromArray [
    ["uid", getPlayerUID player],
    ["name", name player],
    ["loadout", getUnitLoadout player],
    ["position", getPosATL player],
    ["direction", getDir player],
    ["stance", stance player],
    ["email", ""],
    ["phone_number", ""],
    ["state", "HEALTHY"],
    ["holster", true],
    ["organization", "default"]
];

private _result = "forge_server" callExtension ["actor:create", [
    getPlayerUID player,
    toJSON _actor
]];
```

## Update an Actor

`actor:update` accepts a JSON object containing only fields to change.

```sqf
private _patch = createHashMapFromArray [
    ["position", getPosATL player],
    ["direction", getDir player],
    ["stance", stance player],
    ["loadout", getUnitLoadout player]
];

private _result = "forge_server" callExtension ["actor:update", [
    getPlayerUID player,
    toJSON _patch
]];
```

Supported patch fields are `name`, `position`, `direction`, `stance`, `email`,
`phone_number`, `state`, `holster`, `rank`, `organization`, and `loadout`.
`uid` is ignored.

## Hot State

The `actor:hot:*` commands keep a runtime copy of actor data and write it back
only when `actor:hot:save` runs.

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
        actor:hot:init
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      Actor JSON from durable storage.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        actor:hot:get
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      Actor JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        actor:hot:keys
      </code>
    </td>
    
    <td>
      none
    </td>
    
    <td>
      JSON array of hot actor UIDs.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        actor:hot:override
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        actor_json
      </code>
    </td>
    
    <td>
      Actor JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        actor:hot:save
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      Current hot actor JSON and async durable save.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        actor:hot:remove
      </code>
    </td>
    
    <td>
      <code>
        uid
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

Use hot state for frequently updated session data such as position and loadout.
Use durable commands for account creation and administrative changes.

## Error Handling

```sqf
private _result = "forge_server" callExtension ["actor:get", [getPlayerUID player]];
private _payload = _result select 0;

if (_payload find "Error:" == 0) exitWith {
    systemChat format ["Actor error: %1", _payload];
};

private _actor = fromJSON _payload;
```
