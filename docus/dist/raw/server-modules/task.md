# Task Usage Guide

The task module stores transient mission task metadata for active server or
mission lifecycle workflows. SQF still owns Arma-only runtime state such as
objects and participants.

The server addon at `arma/server/addons/task` also owns task execution:
creating BIS tasks, registering task entities, tracking participants, binding
task ownership, applying player/org rewards, and clearing task state when a
task completes.

Runtime dependencies:

- `forge_server_extension`
- `forge_server_common`
- `forge_server_actor`
- `forge_server_bank`
- `forge_server_org`
- `forge_client_notifications`

## Data Model

Catalog entries are flexible JSON objects. The service normalizes these fields
when a catalog entry is inserted or ownership changes:

- `taskId`
- `taskID`
- `accepted`
- `requesterUid`
- `orgID`

Ownership context:

```json
{
  "requesterUid": "76561198000000000",
  "orgId": "default"
}
```

## Commands

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
        task:reset
      </code>
    </td>
    
    <td>
      none
    </td>
    
    <td>
      <code>
        true
      </code>
      
      .
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        task:catalog:active
      </code>
    </td>
    
    <td>
      none
    </td>
    
    <td>
      Active catalog entry array JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        task:catalog:get
      </code>
    </td>
    
    <td>
      <code>
        task_id
      </code>
    </td>
    
    <td>
      Catalog entry JSON or <code>
        null
      </code>
      
      .
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        task:catalog:upsert
      </code>
    </td>
    
    <td>
      <code>
        task_id
      </code>
      
      , <code>
        entry_json
      </code>
    </td>
    
    <td>
      Stored catalog entry JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        task:catalog:delete
      </code>
    </td>
    
    <td>
      <code>
        task_id
      </code>
    </td>
    
    <td>
      <code>
        true
      </code>
      
      .
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        task:ownership:bind
      </code>
    </td>
    
    <td>
      <code>
        task_id
      </code>
      
      , <code>
        ownership_json
      </code>
    </td>
    
    <td>
      Ownership mutation result JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        task:ownership:release
      </code>
    </td>
    
    <td>
      <code>
        task_id
      </code>
    </td>
    
    <td>
      Ownership mutation result JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        task:ownership:accept
      </code>
    </td>
    
    <td>
      <code>
        task_id
      </code>
      
      , <code>
        ownership_json
      </code>
    </td>
    
    <td>
      Ownership mutation result JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        task:ownership:reward_context
      </code>
    </td>
    
    <td>
      <code>
        task_id
      </code>
    </td>
    
    <td>
      Reward context JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        task:status:set
      </code>
    </td>
    
    <td>
      <code>
        task_id
      </code>
      
      , <code>
        status
      </code>
    </td>
    
    <td>
      <code>
        true
      </code>
      
      .
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        task:status:get
      </code>
    </td>
    
    <td>
      <code>
        task_id
      </code>
    </td>
    
    <td>
      Status string JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        task:status:clear
      </code>
    </td>
    
    <td>
      <code>
        task_id
      </code>
    </td>
    
    <td>
      <code>
        true
      </code>
      
      .
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        task:defuse:increment
      </code>
    </td>
    
    <td>
      <code>
        task_id
      </code>
    </td>
    
    <td>
      New counter value JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        task:defuse:get
      </code>
    </td>
    
    <td>
      <code>
        task_id
      </code>
    </td>
    
    <td>
      Counter value JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        task:clear
      </code>
    </td>
    
    <td>
      <code>
        task_id
      </code>
    </td>
    
    <td>
      <code>
        true
      </code>
      
      .
    </td>
  </tr>
</tbody>
</table>

## Upsert a Catalog Entry

```sqf
private _entry = createHashMapFromArray [
    ["title", "Destroy Cache"],
    ["description", "Destroy the enemy supply cache."],
    ["reward", 1500]
];

private _result = "forge_server" callExtension ["task:catalog:upsert", [
    "task-cache-1",
    toJSON _entry
]];
```

## Mark a Task Active

```sqf
"forge_server" callExtension ["task:status:set", [
    "task-cache-1",
    "active"
]];

private _active = "forge_server" callExtension ["task:catalog:active", []];
```

Completed statuses `succeeded` and `failed` are also stored as completed status
fallbacks. Clearing status removes active and completed state.

## Accept a Task

```sqf
private _ownership = createHashMapFromArray [
    ["requesterUid", getPlayerUID player],
    ["orgId", "default"]
];

private _result = "forge_server" callExtension ["task:ownership:accept", [
    "task-cache-1",
    toJSON _ownership
]];
```

`task:ownership:accept` fails if the task is not active or another requester
already accepted it.

## Rewards

```sqf
private _result = "forge_server" callExtension ["task:ownership:reward_context", [
    "task-cache-1"
]];

private _context = fromJSON (_result select 0);
```

The reward context contains `requesterUid` and `orgId`.

## Server Task Flows

The task addon provides these server-owned task flows:

- `attack`
- `defend`
- `defuse`
- `delivery`
- `destroy`
- `hostage`
- `hvt`

Mission designers can create tasks in four ways:

- Eden modules for editor-authored tasks.
- `forge_server_task_fnc_startTask` for script-authored tasks.
- `forge_server_task_fnc_handler` for pre-registered entities with reputation
gating and ownership binding. This path expects the BIS task and catalog
entry to already exist if map-task and CAD visibility are required.
- Direct task function calls for server-owned or mission-authored flows that
intentionally fall back to the `default` org. This path expects the BIS task
to already exist if map-task visibility is required.

The dynamic mission manager can also generate attack tasks from config. That is
system-generated content rather than a hand-authored task creation path.

## CAD Compatibility

CAD hydrates assignable tasks from `TaskStore.getActiveTaskCatalog`. A task must
have a catalog entry and active task status before CAD can show and assign it.

CAD-compatible creation paths:

- Eden modules: compatible because they delegate to
`forge_server_task_fnc_startTask`.
- `forge_server_task_fnc_startTask`: compatible because it registers the
catalog entry, creates the BIS task, and dispatches through the handler.
- Dynamic mission manager attack tasks: compatible because the mission manager
uses `forge_server_task_fnc_startTask`.

Limited or incompatible paths:

- `forge_server_task_fnc_handler`: only compatible if a catalog entry was
already registered elsewhere. The handler sets active status and ownership,
but it does not create the BIS task shown in the map task tab or upsert the
catalog entry.
- Direct task function calls: not CAD-compatible by default. They bypass
`startTask` and usually do not register the task catalog entry or active
status that CAD hydrates from. They also only call `BIS_fnc_taskSetState` at
completion/failure; they do not create the BIS task first.

## BIS Map Task Prerequisite

Only the Eden task modules and `forge_server_task_fnc_startTask` create the BIS
task automatically through `BIS_fnc_taskCreate`.

If a mission uses `forge_server_task_fnc_handler` directly or calls a task flow
function such as `forge_server_task_fnc_attack`, the mission must create a BIS
task with the same task ID before the Forge task completes. Otherwise the
success/failure `BIS_fnc_taskSetState` call has no visible map task to update.

That prerequisite can be satisfied with a vanilla Eden task creation module or
a scripted `BIS_fnc_taskCreate` call. `forge_server_task_fnc_startTask` is the
preferred Forge path because it handles BIS task creation, Forge catalog
registration, entity registration, and handler dispatch together.

## Eden Modules

Eden task modules are the normal designer-facing path. Place the module,
configure its attributes, and sync it to the relevant entities or grouping
modules.

Available task modules:

- `FORGE_Module_Attack`: sync directly to target units or vehicles.
- `FORGE_Module_Destroy`: sync directly to objects, vehicles, or units.
- `FORGE_Module_Defuse`: sync to `FORGE_Module_Explosives` and optionally
`FORGE_Module_Protected`.
- `FORGE_Module_Delivery`: sync to `FORGE_Module_Cargo`; the cargo module syncs
to cargo objects.
- `FORGE_Module_Hostage`: sync to `FORGE_Module_Hostages` and
`FORGE_Module_Shooters`.
- `FORGE_Module_HVT`: sync directly to HVT units.
- `FORGE_Module_Defend`: configure the defense marker and wave settings.

These modules delegate to `forge_server_task_fnc_startTask`.

## Scripted Start Task

Use `forge_server_task_fnc_startTask` when creating tasks from modules,
mission scripts, or generated mission-manager content. It registers task
entities, creates the BIS task, stores the catalog entry, then dispatches
through `forge_server_task_fnc_handler`.

```sqf
[
    "attack",
    "compound_attack_01",
    getPosATL leader1,
    "Attack: East Compound",
    "Eliminate all hostile forces.",
    createHashMapFromArray [["targets", [unit1, unit2, unit3]]],
    createHashMapFromArray [
        ["limitFail", 0],
        ["limitSuccess", 3],
        ["funds", 50000],
        ["ratingFail", -10],
        ["ratingSuccess", 20],
        ["timeLimit", 900]
    ],
    0,
    getPlayerUID player,
    "script"
] call forge_server_task_fnc_startTask;
```

## Handler Calls

Use `forge_server_task_fnc_handler` directly when the task entities are already
registered and you want reputation gating plus ownership binding. Create the
BIS task and catalog entry separately if this task should appear in the map
task tab or CAD:

```sqf
[
    "delivery",
    ["delivery_1", 1, 3, "delivery_zone", 250000, -75, 300, false, false, 900],
    250,
    getPlayerUID player
] call forge_server_task_fnc_handler;
```

## Direct Task Calls

Direct task function calls still work for mission-authored or server-owned
tasks, but they do not provide a requester UID. Ownership falls back to the
`default` org. Create the BIS task separately if this task should appear in the
map task tab.

## Timer Semantics

Task time limits use `0` for no limit:

- attack `timeLimit`
- destroy `timeLimit`
- delivery `timeLimit`
- hostage `timeLimit`
- HVT `timeLimit`

Positive values are measured in seconds. Do not pass `-1` as a no-limit value;
the task runtime treats any non-zero task time limit as active.

Defuse IED timers are different. `iedTimer` must be greater than `0`, because
IEDs are expected to have an active countdown. The Eden defuse module defaults
to `300` seconds.

## Defuse Counter

```sqf
"forge_server" callExtension ["task:defuse:increment", ["task-cache-1"]];
private _count = "forge_server" callExtension ["task:defuse:get", ["task-cache-1"]];
```

## Error Handling

```sqf
private _payload = _result select 0;
if (_payload find "Error:" == 0) exitWith {
    systemChat format ["Task error: %1", _payload];
};
```
