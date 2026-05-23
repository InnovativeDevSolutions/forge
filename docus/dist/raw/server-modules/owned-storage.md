# Owned Storage Usage Guide

Owned storage covers the `owned:locker` and `owned:garage` extension command
groups. These modules store unlock lists rather than physical item or vehicle
instances.

Use these modules for virtual arsenal and virtual garage unlocks. Use
[Locker Usage Guide](/server-modules/locker) and
[Garage Usage Guide](/server-modules/garage) for physical inventory and stored
vehicle instances.

## Owned Locker Model

```json
{
  "items": ["FirstAidKit"],
  "weapons": ["arifle_MX_F"],
  "magazines": ["30Rnd_65x39_caseless_black_mag"],
  "backpacks": ["B_AssaultPack_rgr"]
}
```

Supported owned locker categories:

- `items`
- `weapons`
- `magazines`
- `backpacks`

New owned lockers are created with default unlocks from the Rust model.

## Owned Garage Model

```json
{
  "cars": ["B_Quadbike_01_F"],
  "armor": [],
  "helis": [],
  "planes": [],
  "naval": [],
  "other": []
}
```

Supported owned garage categories:

- `cars`
- `armor`
- `helis`
- `planes`
- `naval`
- `other`

The durable `owned:garage:remove` command currently accepts `heli` for the
helicopter category. Add, get, and hot remove accept `helis`.

New owned garages are created with default unlocks from the Rust model.

## Owned Locker Commands

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
        owned:locker:create
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      Full owned locker JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        owned:locker:fetch
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      Full owned locker JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        owned:locker:get
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        category
      </code>
    </td>
    
    <td>
      Category classname array JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        owned:locker:add
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        category
      </code>
      
      , <code>
        classnames_json
      </code>
    </td>
    
    <td>
      Updated category array JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        owned:locker:remove
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        category
      </code>
      
      , <code>
        classname
      </code>
    </td>
    
    <td>
      Updated category array JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        owned:locker:delete
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
        owned:locker:exists
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

## Owned Garage Commands

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
        owned:garage:create
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      Full owned garage JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        owned:garage:fetch
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      Full owned garage JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        owned:garage:get
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        category
      </code>
    </td>
    
    <td>
      Category classname array JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        owned:garage:add
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        category
      </code>
      
      , <code>
        classnames_json
      </code>
    </td>
    
    <td>
      Updated category array JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        owned:garage:remove
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        category
      </code>
      
      , <code>
        classname
      </code>
    </td>
    
    <td>
      Updated category array JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        owned:garage:delete
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
        owned:garage:exists
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

## Add Virtual Arsenal Unlocks

```sqf
private _classes = ["arifle_MX_F", "hgun_P07_F"];

private _result = "forge_server" callExtension ["owned:locker:add", [
    getPlayerUID player,
    "weapons",
    toJSON _classes
]];
```

## Add Virtual Garage Unlocks

```sqf
private _classes = ["B_Quadbike_01_F", "B_MRAP_01_F"];

private _result = "forge_server" callExtension ["owned:garage:add", [
    getPlayerUID player,
    "cars",
    toJSON _classes
]];
```

## Remove an Unlock

```sqf
"forge_server" callExtension ["owned:locker:remove", [
    getPlayerUID player,
    "weapons",
    "arifle_MX_F"
]];

"forge_server" callExtension ["owned:garage:remove", [
    getPlayerUID player,
    "cars",
    "B_Quadbike_01_F"
]];
```

## Hot-State Commands

Both owned storage modules support hot state.

Owned locker:

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
        owned:locker:hot:init
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      Full owned locker JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        owned:locker:hot:fetch
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      Full owned locker JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        owned:locker:hot:get
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        category
      </code>
    </td>
    
    <td>
      Category array JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        owned:locker:hot:override
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        locker_json
      </code>
    </td>
    
    <td>
      Full owned locker JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        owned:locker:hot:save
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      Current hot owned locker JSON and async durable save.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        owned:locker:hot:remove
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

Owned garage:

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
        owned:garage:hot:init
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      Full owned garage JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        owned:garage:hot:fetch
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      Full owned garage JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        owned:garage:hot:get
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        category
      </code>
    </td>
    
    <td>
      Category array JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        owned:garage:hot:override
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        garage_json
      </code>
    </td>
    
    <td>
      Full owned garage JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        owned:garage:hot:add
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        category
      </code>
      
      , <code>
        classnames_json
      </code>
    </td>
    
    <td>
      Updated category array JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        owned:garage:hot:remove_item
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        category
      </code>
      
      , <code>
        classname
      </code>
    </td>
    
    <td>
      Updated category array JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        owned:garage:hot:save
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      Current hot owned garage JSON and async durable save.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        owned:garage:hot:remove
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

## Error Handling

```sqf
private _payload = _result select 0;
if (_payload find "Error:" == 0) exitWith {
    systemChat format ["Owned storage error: %1", _payload];
};
```
