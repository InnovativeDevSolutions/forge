# Client CAD Usage Guide

The client CAD addon provides the map and dispatch UI for groups, active
tasks, task assignment, dispatch orders, support requests, and task
acknowledge/decline workflows.

## Open CAD UI

```sqf
call forge_client_cad_fnc_openUI;
```

The CAD UI opens `RscMapUI` and loads separate browser controls for:

- top bar
- bottom bar
- side panel
- dispatcher board

The native Arma map remains part of the same display.

## Repository and Bridge

`forge_client_cad_fnc_initRepository` caches the hydrated CAD payload,
selected mode, dispatch view, session data, groups, tasks, requests, and
assignments.

`forge_client_cad_fnc_initUIBridge` owns:

- ready state for side panel, top bar, and dispatcher board
- operations vs dispatch mode
- board vs map dispatch view
- hydrate requests
- task assignment, acknowledge, and decline requests
- dispatch order create/close requests
- support request submit/close requests
- group status, role, and profile requests
- map focus actions

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
        cad::topbar::ready
      </code>
    </td>
    
    <td>
      Mark top bar ready and push top bar state.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad::ready
      </code>
    </td>
    
    <td>
      Mark side panel ready and request hydrate.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad::dispatcher::ready
      </code>
    </td>
    
    <td>
      Mark dispatcher board ready and push hydrate data.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad::mode::set
      </code>
    </td>
    
    <td>
      Switch between operations and dispatch mode.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad::dispatchView::set
      </code>
    </td>
    
    <td>
      Switch dispatch board/map view.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad::refresh
      </code>
    </td>
    
    <td>
      Request fresh CAD hydrate data.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad::tasks::assign
      </code>
    </td>
    
    <td>
      Assign a task to a group.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad::tasks::acknowledge
      </code>
    </td>
    
    <td>
      Acknowledge assigned task.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad::tasks::decline
      </code>
    </td>
    
    <td>
      Decline assigned task.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad::dispatchOrder::create
      </code>
    </td>
    
    <td>
      Create dispatch order.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad::dispatchOrder::close
      </code>
    </td>
    
    <td>
      Close dispatch order.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad::supportRequest::submit
      </code>
    </td>
    
    <td>
      Submit support request.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad::supportRequest::close
      </code>
    </td>
    
    <td>
      Close support request.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad::groups::status
      </code>
    </td>
    
    <td>
      Update group status.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad::groups::role
      </code>
    </td>
    
    <td>
      Update group role.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad::groups::profile
      </code>
    </td>
    
    <td>
      Update status and role together.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad::groups::focus
      </code>
    </td>
    
    <td>
      Center map on a group.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad::tasks::focus
      </code>
    </td>
    
    <td>
      Center map on a task.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad::requests::focus
      </code>
    </td>
    
    <td>
      Center map on a support request.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        map::zoomIn
      </code>
    </td>
    
    <td>
      Zoom native map in.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        map::zoomOut
      </code>
    </td>
    
    <td>
      Zoom native map out.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        map::search
      </code>
    </td>
    
    <td>
      Placeholder status update.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        map::close
      </code>
    </td>
    
    <td>
      Dispose bridge state and close the display.
    </td>
  </tr>
</tbody>
</table>

## Response Events

The bridge pushes:

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
        cad::hydrate
      </code>
    </td>
    
    <td>
      Full hydrated CAD payload to the side panel.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad::assignment::response
      </code>
    </td>
    
    <td>
      Task assignment/acknowledge/decline result.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad::group::response
      </code>
    </td>
    
    <td>
      Group status/role/profile result.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad::request::response
      </code>
    </td>
    
    <td>
      Support request result.
    </td>
  </tr>
</tbody>
</table>

Dispatcher board controls also receive direct `ExecJS` status and hydrate
calls.

## Task Compatibility

CAD task visibility depends on server-side task catalog entries. Tasks created
through Eden Forge task modules or `forge_server_task_fnc_startTask` are the
normal CAD-compatible task sources because they register task catalog data.

Direct handler or task-function calls only work with CAD when the task catalog
entry already exists.

## Authorization Notes

Only dispatcher sessions can enter dispatch mode. If the hydrated session is
not a dispatcher, the bridge forces the UI back to operations mode.

## Related Guides

- [CAD Usage Guide](/server-modules/cad)
- [Task Usage Guide](/server-modules/task)
- [Client Common Usage Guide](/client-addons/common)
