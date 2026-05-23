# Garage Usage Guide

The garage module stores physical player vehicles. Each record keeps the
vehicle classname, generated plate UUID, fuel, overall damage, and detailed hit
point damage.

## Storage Model

Garage data is persisted through SurrealDB by the server extension.

```json
{
  "plate-uuid": {
    "plate": "plate-uuid",
    "classname": "B_Quadbike_01_F",
    "fuel": 1.0,
    "damage": 0.0,
    "hit_points": {
      "names": ["hitengine"],
      "selections": ["engine_hitpoint"],
      "values": [0.0]
    }
  }
}
```

Rules validated by the Rust service:

- A player garage can contain up to 5 vehicles.
- `garage:add` generates a UUID plate automatically.
- `fuel`, `damage`, and every hit point value must be between `0.0` and `1.0`.
- `hit_points.names`, `hit_points.selections`, and `hit_points.values` must have
the same length.
- `garage:get`, `garage:patch`, and `garage:remove` require an existing garage.
- `garage:add` creates an empty garage automatically when one does not exist.

## Commands

All commands are called on the `garage` group.

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
        garage:create
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      Empty vehicle map as JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        garage:get
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      Vehicle map as JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        garage:add
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        vehicle_json
      </code>
    </td>
    
    <td>
      Updated vehicle map as JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        garage:update
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        vehicles_json
      </code>
    </td>
    
    <td>
      Replaced vehicle map as JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        garage:patch
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
      Updated vehicle map as JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        garage:remove
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        remove_json
      </code>
    </td>
    
    <td>
      Updated vehicle map as JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        garage:delete
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
  
  <tr>
    <td>
      <code>
        garage:exists
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
</tbody>
</table>

## Error Handling

Every command returns a string payload. Always check for the `Error:` prefix
before parsing JSON.

```sqf
private _result = "forge_server" callExtension ["garage:get", [getPlayerUID player]];
private _payload = _result select 0;

if (_payload find "Error:" == 0) exitWith {
    systemChat format ["Garage error: %1", _payload];
};

private _garage = fromJSON _payload;
```

## Add a Vehicle

`garage:add` requires `classname`, `fuel`, `damage`, and `hit_points`.

```sqf
private _hitPointData = getAllHitPointsDamage _vehicle;
private _hitPoints = createHashMapFromArray [
    ["names", _hitPointData select 0],
    ["selections", _hitPointData select 1],
    ["values", _hitPointData select 2]
];

private _vehicleData = createHashMapFromArray [
    ["classname", typeOf _vehicle],
    ["fuel", fuel _vehicle],
    ["damage", damage _vehicle],
    ["hit_points", _hitPoints]
];

private _result = "forge_server" callExtension ["garage:add", [
    getPlayerUID player,
    toJSON _vehicleData
]];

private _payload = _result select 0;
if (_payload find "Error:" == 0) exitWith {
    hint format ["Failed to store vehicle: %1", _payload];
};

private _garage = fromJSON _payload;
```

The returned value is a hash map keyed by generated plate. To find the newly
stored vehicle, compare returned keys before and after the add, or search by
classname if your workflow guarantees a unique pending vehicle.

```sqf
private _storedPlate = "";
{
    private _vehicleRecord = _garage get _x;
    if ((_vehicleRecord get "classname") == typeOf _vehicle) then {
        _storedPlate = _x;
    };
} forEach keys _garage;
```

## Patch a Vehicle

`garage:patch` updates selected fields for one plate. The `plate` field is
required. `fuel`, `damage`, and `hit_points` are optional.

```sqf
private _patch = createHashMapFromArray [
    ["plate", _vehicle getVariable ["forge_garage_plate", ""]],
    ["fuel", fuel _vehicle],
    ["damage", damage _vehicle]
];

private _result = "forge_server" callExtension ["garage:patch", [
    getPlayerUID player,
    toJSON _patch
]];
```

## Remove a Vehicle

`garage:remove` expects JSON with a `plate` field.

```sqf
private _remove = createHashMapFromArray [
    ["plate", _plate]
];

private _result = "forge_server" callExtension ["garage:remove", [
    getPlayerUID player,
    toJSON _remove
]];
```

## Spawn a Stored Vehicle

```sqf
fnc_spawnGarageVehicle = {
    params ["_plate"];

    private _result = "forge_server" callExtension ["garage:get", [getPlayerUID player]];
    private _payload = _result select 0;

    if (_payload find "Error:" == 0) exitWith {
        hint format ["Failed to load garage: %1", _payload];
        objNull
    };

    private _garage = fromJSON _payload;
    private _vehicleData = _garage getOrDefault [_plate, createHashMap];
    if (_vehicleData isEqualTo createHashMap) exitWith {
        hint "Vehicle plate was not found in your garage.";
        objNull
    };

    private _vehicle = (_vehicleData get "classname") createVehicle (player getPos [10, getDir player]);
    _vehicle setFuel (_vehicleData getOrDefault ["fuel", 1]);
    _vehicle setDamage (_vehicleData getOrDefault ["damage", 0]);
    _vehicle setVariable ["forge_garage_plate", _plate, true];

    private _hitPoints = _vehicleData getOrDefault ["hit_points", createHashMap];
    private _names = _hitPoints getOrDefault ["names", []];
    private _values = _hitPoints getOrDefault ["values", []];

    {
        _vehicle setHitPointDamage [_x, _values select _forEachIndex];
    } forEach _names;

    private _remove = createHashMapFromArray [["plate", _plate]];
    "forge_server" callExtension ["garage:remove", [getPlayerUID player, toJSON _remove]];

    _vehicle
};
```

## Hot State

The `garage:hot:*` commands keep a runtime copy of a player's garage and write
it back only when `garage:hot:save` runs.

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
        garage:hot:init
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      Vehicle map as JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        garage:hot:get
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      Vehicle map as JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        garage:hot:override
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        vehicles_json
      </code>
    </td>
    
    <td>
      Vehicle map as JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        garage:hot:add
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        vehicle_json
      </code>
    </td>
    
    <td>
      Vehicle map as JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        garage:hot:remove_vehicle
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        remove_json
      </code>
    </td>
    
    <td>
      Vehicle map as JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        garage:hot:save
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      Current hot vehicle map as JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        garage:hot:remove
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

Use hot state for session-heavy vehicle workflows. Use the durable commands for
simple store/retrieve operations.

## Best Practices

- Store the generated plate on spawned vehicles with `setVariable`.
- Use `garage:patch` for frequent fuel and damage syncs.
- Use `garage:update` only when replacing the whole vehicle map intentionally.
- Do not delete the world vehicle until `garage:add` succeeds.
- Treat vehicle maps as hash maps keyed by plate, not arrays.
