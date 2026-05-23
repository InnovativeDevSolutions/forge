# CAD Usage Guide

The CAD module stores transient operational state for dispatch activity,
assignments, dispatch orders, support requests, group profiles, grouped views,
and hydrated UI payloads. CAD state is in-memory and follows the active server
or mission lifecycle.

## Data Model

Most CAD records are flexible JSON objects. The service normalizes important
IDs and returns structured mutation results for higher-level workflows.

Common generated IDs:

- Orders: `cad-order:<sequence>`
- Requests: `cad-request:<sequence>`
- Assignments usually share a task ID or order ID.

## Commands

### Activity

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
        cad:activity:append
      </code>
    </td>
    
    <td>
      <code>
        activity_json
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
        cad:activity:recent
      </code>
    </td>
    
    <td>
      <code>
        limit
      </code>
    </td>
    
    <td>
      Recent activity array JSON.
    </td>
  </tr>
</tbody>
</table>

### Assignments

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
        cad:assignments:list
      </code>
    </td>
    
    <td>
      none
    </td>
    
    <td>
      Assignment array JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad:assignments:assign
      </code>
    </td>
    
    <td>
      <code>
        entry_id
      </code>
      
      , <code>
        assignment_json
      </code>
    </td>
    
    <td>
      Assignment mutation result JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad:assignments:acknowledge
      </code>
    </td>
    
    <td>
      <code>
        entry_id
      </code>
      
      , <code>
        patch_json
      </code>
    </td>
    
    <td>
      Assignment mutation result JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad:assignments:decline
      </code>
    </td>
    
    <td>
      <code>
        entry_id
      </code>
      
      , <code>
        patch_json
      </code>
    </td>
    
    <td>
      Assignment mutation result JSON and removes assignment.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad:assignments:upsert
      </code>
    </td>
    
    <td>
      <code>
        entry_id
      </code>
      
      , <code>
        assignment_json
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
        cad:assignments:delete
      </code>
    </td>
    
    <td>
      <code>
        entry_id
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

### Orders

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
        cad:orders:list
      </code>
    </td>
    
    <td>
      none
    </td>
    
    <td>
      Order array JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad:orders:create
      </code>
    </td>
    
    <td>
      <code>
        order_seed_json
      </code>
    </td>
    
    <td>
      Dispatch order mutation result JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad:orders:create_from_context
      </code>
    </td>
    
    <td>
      <code>
        context_json
      </code>
    </td>
    
    <td>
      Dispatch order mutation result JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad:orders:close
      </code>
    </td>
    
    <td>
      <code>
        entry_id
      </code>
    </td>
    
    <td>
      Dispatch order mutation result JSON and removes order/assignment.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad:orders:upsert
      </code>
    </td>
    
    <td>
      <code>
        entry_id
      </code>
      
      , <code>
        order_json
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
        cad:orders:delete
      </code>
    </td>
    
    <td>
      <code>
        entry_id
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

### Requests

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
        cad:requests:list
      </code>
    </td>
    
    <td>
      none
    </td>
    
    <td>
      Request array JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad:requests:submit
      </code>
    </td>
    
    <td>
      <code>
        request_json
      </code>
    </td>
    
    <td>
      Request mutation result JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad:requests:submit_from_context
      </code>
    </td>
    
    <td>
      <code>
        context_json
      </code>
    </td>
    
    <td>
      Request mutation result JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad:requests:close
      </code>
    </td>
    
    <td>
      <code>
        entry_id
      </code>
    </td>
    
    <td>
      Request mutation result JSON and removes request.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad:requests:upsert
      </code>
    </td>
    
    <td>
      <code>
        entry_id
      </code>
      
      , <code>
        request_json
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
        cad:requests:delete
      </code>
    </td>
    
    <td>
      <code>
        entry_id
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

### Profiles and Views

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
        cad:profiles:list
      </code>
    </td>
    
    <td>
      none
    </td>
    
    <td>
      Profile array JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad:profiles:update_from_context
      </code>
    </td>
    
    <td>
      <code>
        context_json
      </code>
    </td>
    
    <td>
      Profile mutation result JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad:profiles:upsert
      </code>
    </td>
    
    <td>
      <code>
        entry_id
      </code>
      
      , <code>
        profile_json
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
        cad:profiles:delete
      </code>
    </td>
    
    <td>
      <code>
        entry_id
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
        cad:groups:build
      </code>
    </td>
    
    <td>
      <code>
        groups_seed_json
      </code>
    </td>
    
    <td>
      Group array JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad:view:hydrate
      </code>
    </td>
    
    <td>
      <code>
        hydrate_seed_json
      </code>
    </td>
    
    <td>
      Hydrated CAD payload JSON.
    </td>
  </tr>
</tbody>
</table>

## Submit a Support Request

```sqf
private _fields = createHashMapFromArray [
    ["pickup_location", "Grid 123456"],
    ["precedence", "urgent"],
    ["security", "secure"]
];

private _context = createHashMapFromArray [
    ["type", "medevac_9line"],
    ["fields", _fields],
    ["groupId", "alpha"],
    ["groupCallsign", "Alpha 1-1"],
    ["submittedByUid", getPlayerUID player],
    ["submittedByName", name player],
    ["priority", "emergency"],
    ["position", getPosATL player],
    ["createdAt", diag_tickTime]
];

private _result = "forge_server" callExtension ["cad:requests:submit_from_context", [
    toJSON _context
]];
```

Supported priority values are `routine`, `priority`, and `emergency`. Unknown
values normalize to `priority`.

## Create a Dispatch Order

```sqf
private _context = createHashMapFromArray [
    ["assigneeGroupId", "bravo"],
    ["assigneeGroupCallsign", "Bravo 1-1"],
    ["targetGroupId", "alpha"],
    ["targetGroupCallsign", "Alpha 1-1"],
    ["targetPosition", getPosATL player],
    ["createdByUid", getPlayerUID player],
    ["createdByName", name player],
    ["requestId", "cad-request:1"],
    ["requestType", "logreq"],
    ["requestTitle", "LOGREQ | Alpha 1-1"],
    ["requestSummary", "Ammo resupply requested"],
    ["requestFields", createHashMap],
    ["note", "Support Alpha 1-1 at current position."],
    ["priority", "priority"],
    ["createdAt", diag_tickTime]
];

private _result = "forge_server" callExtension ["cad:orders:create_from_context", [
    toJSON _context
]];
```

## Assignment Workflow

```sqf
private _assignment = createHashMapFromArray [
    ["groupId", "bravo"],
    ["assigneeGroupCallsign", "Bravo 1-1"],
    ["assignedByUid", getPlayerUID player],
    ["assignedByName", name player],
    ["assignedAt", diag_tickTime],
    ["state", "assigned"]
];

"forge_server" callExtension ["cad:assignments:assign", [
    "task-123",
    toJSON _assignment
]];

private _ack = createHashMapFromArray [
    ["state", "acknowledged"],
    ["acknowledgedByUid", getPlayerUID player],
    ["acknowledgedAt", diag_tickTime]
];

"forge_server" callExtension ["cad:assignments:acknowledge", [
    "task-123",
    toJSON _ack
]];
```

## Hydrate the CAD UI

```sqf
private _session = createHashMapFromArray [
    ["uid", getPlayerUID player],
    ["orgId", "default"],
    ["isDispatcher", true],
    ["groupId", "alpha"],
    ["isLeader", true]
];

private _seed = createHashMapFromArray [
    ["groups", _liveGroups],
    ["activeTasks", _activeTasks],
    ["session", _session]
];

private _result = "forge_server" callExtension ["cad:view:hydrate", [toJSON _seed]];
```

## Error Handling

```sqf
private _payload = _result select 0;
if (_payload find "Error:" == 0) exitWith {
    systemChat format ["CAD error: %1", _payload];
};
```
