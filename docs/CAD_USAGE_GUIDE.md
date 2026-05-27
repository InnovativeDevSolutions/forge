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

| Command | Arguments | Returns |
| --- | --- | --- |
| `cad:activity:append` | `activity_json` | `OK`. |
| `cad:activity:recent` | `limit` | Recent activity array JSON. |

### Assignments

| Command | Arguments | Returns |
| --- | --- | --- |
| `cad:assignments:list` | none | Assignment array JSON. |
| `cad:assignments:assign` | `entry_id`, `assignment_json` | Assignment mutation result JSON. |
| `cad:assignments:acknowledge` | `entry_id`, `patch_json` | Assignment mutation result JSON. |
| `cad:assignments:decline` | `entry_id`, `patch_json` | Assignment mutation result JSON and removes assignment. |
| `cad:assignments:upsert` | `entry_id`, `assignment_json` | `OK`. |
| `cad:assignments:delete` | `entry_id` | `OK`. |

### Orders

| Command | Arguments | Returns |
| --- | --- | --- |
| `cad:orders:list` | none | Order array JSON. |
| `cad:orders:create` | `order_seed_json` | Dispatch order mutation result JSON. |
| `cad:orders:create_from_context` | `context_json` | Dispatch order mutation result JSON. |
| `cad:orders:close` | `entry_id` | Dispatch order mutation result JSON and removes order/assignment. |
| `cad:orders:upsert` | `entry_id`, `order_json` | `OK`. |
| `cad:orders:delete` | `entry_id` | `OK`. |

### Requests

| Command | Arguments | Returns |
| --- | --- | --- |
| `cad:requests:list` | none | Request array JSON. |
| `cad:requests:submit` | `request_json` | Request mutation result JSON. |
| `cad:requests:submit_from_context` | `context_json` | Request mutation result JSON. |
| `cad:requests:close` | `entry_id` | Request mutation result JSON and removes request. |
| `cad:requests:upsert` | `entry_id`, `request_json` | `OK`. |
| `cad:requests:delete` | `entry_id` | `OK`. |

### Profiles and Views

| Command | Arguments | Returns |
| --- | --- | --- |
| `cad:profiles:list` | none | Profile array JSON. |
| `cad:profiles:update_from_context` | `context_json` | Profile mutation result JSON. |
| `cad:profiles:upsert` | `entry_id`, `profile_json` | `OK`. |
| `cad:profiles:delete` | `entry_id` | `OK`. |
| `cad:groups:build` | `groups_seed_json` | Group array JSON. |
| `cad:view:hydrate` | `hydrate_seed_json` | Hydrated CAD payload JSON. |

## Generated Mission Requests

Dispatchers can request framework-generated mission tasks from the CAD
dispatcher board. The server hydrates the available generated task types from
the task mission manager as `generatedTaskTypes`; the client uses that hydrated
list for the dropdown.

Generated mission requests are controlled by the server CBA setting
`forge_task_enableGenerator`:

- Enabled: CAD receives the generated task type list and dispatchers can request
  a specific generator type.
- Disabled: CAD receives an empty generated task type list, the task request UI
  is disabled, and server-side request handling rejects any manual request.

The framework-owned request entry point is
`forge_server_task_fnc_requestMissionTask`. Server CAD calls that first and only
falls back to a mission-local `forge_pmc_fnc_requestMissionTask` when the
framework entry point is unavailable.

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

Task contracts have two separate phases. Dispatch assignment reserves a
contract for a group and sets the CAD assignment state to `assigned`, but it
does not accept or start the task. The assigned group leader must acknowledge
the assignment before task ownership is bound and task logic starts. If the
leader declines, the CAD assignment is removed and the contract returns to the
open board. Task status follows the same lifecycle: `available` on creation,
`assigned` after dispatch assignment, and `active` after acknowledgement.

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
    ["generatedTaskTypes", _generatedTaskTypes],
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
