# Client Garage Usage Guide

The client garage addon provides player vehicle storage UI, vehicle
store/retrieve actions, selected nearby vehicle service requests, vehicle
context building, and the virtual garage view.

## Open Garage UI

```sqf
call forge_client_garage_fnc_openUI;
```

The garage UI opens `RscGarage`, loads `ui/_site/index.html`, and routes
browser events through `forge_client_garage_fnc_handleUIEvents`.

## Open Virtual Garage

```sqf
call forge_client_garage_fnc_openVG;
```

The virtual garage uses mission-configured `FORGE_CfgGarages` locations to set
the spawn/preview position, opens the BIS garage interface, and restricts the
available vehicle lists from the virtual garage repository.

## Client Services

<table>
<thead>
  <tr>
    <th>
      Service
    </th>
    
    <th>
      Purpose
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        GarageRepository
      </code>
    </td>
    
    <td>
      Player garage view state.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        VGRepository
      </code>
    </td>
    
    <td>
      Virtual garage unlock view state.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        GarageHelperService
      </code>
    </td>
    
    <td>
      Vehicle names, hit points, and payload helpers.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        GarageContextService
      </code>
    </td>
    
    <td>
      Nearby/current vehicle context.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        GaragePayloadService
      </code>
    </td>
    
    <td>
      Browser hydrate payload construction.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        GarageActionService
      </code>
    </td>
    
    <td>
      Store/retrieve request handling and selected nearby vehicle refuel/repair request forwarding.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        GarageUIBridge
      </code>
    </td>
    
    <td>
      Browser ready, hydrate, and sync delivery.
    </td>
  </tr>
</tbody>
</table>

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
        garage::ready
      </code>
    </td>
    
    <td>
      Mark browser ready and send <code>
        garage::hydrate
      </code>
      
      .
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        garage::refresh
      </code>
    </td>
    
    <td>
      Send current garage payload as <code>
        garage::sync
      </code>
      
      .
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        garage::vehicle::retrieve::request
      </code>
    </td>
    
    <td>
      Forward retrieve request through the action service.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        garage::vehicle::store::request
      </code>
    </td>
    
    <td>
      Forward store request through the action service.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        garage::vehicle::refuel::request
      </code>
    </td>
    
    <td>
      Forward selected nearby vehicle refuel request to the server economy service.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        garage::vehicle::repair::request
      </code>
    </td>
    
    <td>
      Forward selected nearby vehicle repair request to the server economy service.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        garage::close
      </code>
    </td>
    
    <td>
      Dispose bridge screen state and close the display.
    </td>
  </tr>
</tbody>
</table>

## Browser Response Events

<table>
<thead>
  <tr>
    <th>
      Event
    </th>
    
    <th>
      Purpose
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        garage::hydrate
      </code>
    </td>
    
    <td>
      Initial vehicle and session payload.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        garage::sync
      </code>
    </td>
    
    <td>
      Refreshed vehicle payload.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        garage::service::success
      </code>
    </td>
    
    <td>
      Browser notice for accepted refuel/repair requests.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        garage::service::failure
      </code>
    </td>
    
    <td>
      Browser notice for rejected refuel/repair requests.
    </td>
  </tr>
</tbody>
</table>

Server action responses are handled by the action service and notification
flow.

## Vehicle Service

The selected vehicle detail panel includes refuel and repair actions for nearby
world vehicles. Stored records must be retrieved first because server economy
services operate on live vehicle objects, not stored garage records.

Refuel requests use the server economy `RefuelService` event. Repair requests
use the server economy `RepairService` event. Both services are billed by the
server economy addon through organization funds.

## Mission Setup

Garage interactions are normally surfaced through the actor menu when nearby
objects have garage variables such as:

```sqf
_object setVariable ["isGarage", true, true];
_object setVariable ["garageType", "cars", true];
```

Virtual garage access also requires configured garage locations in mission
config so the preview/spawn position can be resolved.

## Authoritative State

The client gathers vehicle context and sends store/retrieve requests. Stored
vehicle state, validation, spawning, removal, and persistence are owned by the
server garage addon and extension.

## Related Guides

- [Garage Usage Guide](/server-modules/garage)
- [Client Actor Usage Guide](/client-addons/actor)
- [Client Notifications Usage Guide](/client-addons/notifications)
