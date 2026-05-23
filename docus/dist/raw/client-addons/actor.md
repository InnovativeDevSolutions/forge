# Client Actor Usage Guide

The client actor addon owns the player interaction menu and client-side actor
repository. It is the main launcher for nearby player actions and other Forge
client UIs.

## Open the Actor Menu

```sqf
call forge_client_actor_fnc_openUI;
```

The actor menu opens `RscActorMenu`, loads `ui/_site/index.html`, and routes
browser alerts through `forge_client_actor_fnc_handleUIEvents`.

## Repository

`forge_client_actor_fnc_initRepository` creates `GVAR(ActorRepository)`.

The repository:

- requests actor initialization from the server
- saves actor state through the server actor addon
- caches client-visible actor fields
- applies position, direction, stance, rank, and loadout on JIP sync when the
relevant settings allow it
- provides nearby interaction actions to the browser UI

Initialize actor state through the repository:

```sqf
GVAR(ActorRepository) call ["init", []];
```

Save actor state through the server:

```sqf
GVAR(ActorRepository) call ["save", [true]];
```

## Nearby Actions

The menu asks for nearby actions with:

```text
actor::get::actions
```

The repository scans objects within 5 meters and returns actions based on
mission object variables:

<table>
<thead>
  <tr>
    <th>
      Variable
    </th>
    
    <th>
      Action
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        storeType
      </code>
    </td>
    
    <td>
      store
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        isAtm
      </code>
    </td>
    
    <td>
      ATM
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        isBank
      </code>
    </td>
    
    <td>
      bank
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        isGarage
      </code>
    </td>
    
    <td>
      garage
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        garageType
      </code>
    </td>
    
    <td>
      garage subtype
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        isLocker
      </code>
    </td>
    
    <td>
      virtual arsenal action when VA is enabled
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        deviceType
      </code>
    </td>
    
    <td>
      device action placeholder
    </td>
  </tr>
  
  <tr>
    <td>
      nearby player unit
    </td>
    
    <td>
      player interaction placeholder
    </td>
  </tr>
</tbody>
</table>

The response is pushed into the browser with `updateAvailableActions(...)`.

## Browser Events

<table>
<thead>
  <tr>
    <th>
      Event
    </th>
    
    <th>
      Client behavior
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        actor::get::actions
      </code>
    </td>
    
    <td>
      Refresh nearby actions.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        actor::close::menu
      </code>
    </td>
    
    <td>
      Close actor menu.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        actor::open::atm
      </code>
    </td>
    
    <td>
      Open bank UI in ATM mode.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        actor::open::bank
      </code>
    </td>
    
    <td>
      Open bank UI in bank mode.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        actor::open::cad
      </code>
    </td>
    
    <td>
      Open CAD UI.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        actor::open::garage
      </code>
    </td>
    
    <td>
      Open garage UI.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        actor::open::vgarage
      </code>
    </td>
    
    <td>
      Open virtual garage.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        actor::open::org
      </code>
    </td>
    
    <td>
      Open organization UI.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        actor::open::vlocker
      </code>
    </td>
    
    <td>
      Open ACE arsenal on <code>
        FORGE_Locker_Box
      </code>
      
      .
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        actor::open::phone
      </code>
    </td>
    
    <td>
      Open phone UI.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        actor::open::store
      </code>
    </td>
    
    <td>
      Open store UI.
    </td>
  </tr>
</tbody>
</table>

Device and player interaction events currently display placeholder feedback.

## Authoritative State

Actor persistence is server-owned. The client repository requests and displays
actor data, but actor creation, durable updates, and hot-state behavior are
handled by the server actor addon and extension.

## Related Guides

- [Actor Usage Guide](/server-modules/actor)
- [Client Bank Usage Guide](/client-addons/bank)
- [Client CAD Usage Guide](/client-addons/cad)
- [Client Garage Usage Guide](/client-addons/garage)
- [Client Locker Usage Guide](/client-addons/locker)
- [Client Organization Usage Guide](/client-addons/organization)
- [Client Phone Usage Guide](/client-addons/phone)
- [Client Store Usage Guide](/client-addons/store)
