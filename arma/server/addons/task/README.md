# Forge Task Module

## Overview
The task addon is a server-owned mission/task system for Forge. It manages task execution, task-owned state, participant tracking, contribution-based player earnings, and org-owned rewards.

Task operational state is mission-scoped. The extension-backed task catalog,
ownership, status, and defuse state are reset on task store startup, so the
system intentionally starts clean after each server or mission restart.

## Responsibilities
- spawn and monitor task flows on the server
- track per-task entities through `TaskStore`
- track task participants and engine-rating contribution
- award player earnings through the bank module
- award org funds, reputation, assets, and fleet rewards
- notify task participants and sync org updates to online members

## Dependencies
- `forge_server_extension`
- `forge_server_common`
- `forge_server_actor`
- `forge_server_bank`
- `forge_server_org`
- `forge_client_notifications`

## Main Components

### Task Flows
- `fnc_attack.sqf`
- `fnc_defend.sqf`
- `fnc_defuse.sqf`
- `fnc_delivery.sqf`
- `fnc_destroy.sqf`
- `fnc_hostage.sqf`
- `fnc_hvt.sqf`

### TaskStore
`fnc_initTaskStore.sqf` initializes `TaskStore`, which owns:
- task ownership bindings
- participant snapshots
- defuse progress
- per-task entity registries for cargo, hostages, HVTs, IEDs, protected entities, shooters, and targets

**Public API Methods:**
- **Lifecycle**: `bindTaskOwnership`, `releaseTaskOwnership`, `registerTaskCatalogEntry`, `setTaskStatus`, `getTaskStatus`, `clearTaskStatus`, `clearTask`
- **Catalog**: `getActiveTaskCatalog`, `hasTaskCatalogEntry`, `getTaskCatalogEntry`
- **Entities**: `registerTaskEntity`, `getTaskEntities`, `findTaskEntityOwner`, `clearTaskEntities`
- **Participants**: `acceptTask`, `isTaskAccepted`, `trackParticipants`, `getTaskParticipants`, `getTaskParticipantUids`, `notifyParticipants`
- **Rewards**: `resolveRewardContext`, `applyRatingOutcome`, `incrementDefuseCount`, `getDefuseCount`
- **Events**: `emitTaskLifecycleEvent`, `buildTaskLifecycleEventPayload`
- **Utilities**: `callTaskState`, `callTaskStateEnvelope`

### Object Model
Object-style task instances and entity controllers live under
`functions/objects/` and are initialized directly from `XEH_preInit.sqf`.

- `TaskInstanceBaseClass`
- `EntityControllerBaseClass`
- `functions/objects/README.md`

The task functions are compatibility adapters around these object-style task
classes. This keeps the public task function names stable while moving stateful
task behavior into per-task `createHashMapObject` instances.

### Reward Handling
`fnc_handleTaskRewards.sqf` applies org-owned rewards:
- `funds` -> org funds
- `equipment`, `supplies`, `weapons`, `special` -> org assets
- `vehicles` -> org fleet

Player `earnings` and org `reputation` from task outcomes are distributed separately through `TaskStore.applyRatingOutcome` using Arma engine `rating` deltas.

## Task Ownership
Tasks are bound to an owner org when they are started through `fnc_handler.sqf`.

- if a requester UID is provided, the task is owned by that requester's org
- if no requester UID is available, the task is bound to the `default` org

Org rewards always go to the bound owner org. Player earnings still use per-player contribution.

## Usage

Task time limits use `0` for no limit on attack, destroy, delivery, hostage,
and HVT tasks. Defuse IED timers are different: each IED must have a positive
countdown value.

Mission designers can create tasks in four ways:

- Eden modules for editor-authored tasks.
- `fnc_startTask.sqf` for script-authored tasks.
- `fnc_handler.sqf` for pre-registered entities with reputation gating and
  ownership binding. This path expects the BIS task and catalog entry to
  already exist if map-task and CAD visibility are required.
- Direct task function calls for server-owned or mission-authored flows that
  intentionally fall back to the `default` org. This path expects the BIS task
  to already exist if map-task visibility is required.

The dynamic mission manager can also generate attack, defend, defuse, delivery,
destroy, hostage, HVT kill, and HVT capture tasks from config. That is
system-generated content rather than a hand-authored task creation path.

### CAD Compatibility
CAD hydrates assignable tasks from `TaskStore.getActiveTaskCatalog`. A task must
have a catalog entry and a task status of `available`, `assigned`, or `active`
before CAD can show it.
CAD assignment reserves a task for a group, but task logic waits until the
assigned group leader acknowledges the assignment. Declined assignments return
to the open CAD board.

CAD-compatible creation paths:
- Eden modules: compatible because they delegate to `fnc_startTask.sqf`
- `fnc_startTask.sqf`: compatible because it registers the catalog entry,
  creates the BIS task, and dispatches through `fnc_handler.sqf`
- dynamic mission manager tasks: compatible because the mission manager
  uses `fnc_startTask.sqf`

Limited or incompatible paths:
- `fnc_handler.sqf`: only compatible if a catalog entry was already registered
  elsewhere. The handler sets available status and ownership, but it does not
  create the BIS task shown in the map task tab or upsert the catalog entry
- direct task function calls: not CAD-compatible by default. They bypass
  `fnc_startTask.sqf` and usually do not register the task catalog entry or
  available/assigned/active status that CAD hydrates from. They also only call
  `BIS_fnc_taskSetState` at completion/failure; they do not create the BIS task
  first

### BIS Map Task Prerequisite
Only the Eden task modules and `fnc_startTask.sqf` create the BIS task
automatically through `BIS_fnc_taskCreate`.

If a mission uses `fnc_handler.sqf` directly or calls a task flow function such
as `forge_server_task_fnc_attack`, the mission must create a BIS task with the
same task ID before the Forge task completes. Otherwise the success/failure
`BIS_fnc_taskSetState` call has no visible map task to update.

That prerequisite can be satisfied with a vanilla Eden task creation module or
a scripted `BIS_fnc_taskCreate` call. `fnc_startTask.sqf` is the preferred Forge
path because it handles BIS task creation, Forge catalog registration, entity
registration, and handler dispatch together.

### Create With Eden Modules
Eden task modules are the normal designer-facing path. Place the module,
configure its attributes, and sync it to the relevant entities or grouping
modules.

For a mission-designer-focused step-by-step setup guide, see:

- `docs/TASK_USAGE_GUIDE.md`

Available task modules:
- `FORGE_Module_Attack`: sync directly to target units or vehicles
- `FORGE_Module_Destroy`: sync directly to objects, vehicles, or units
- `FORGE_Module_Defuse`: sync to `FORGE_Module_Explosives` and optionally
  `FORGE_Module_Protected`
- `FORGE_Module_Delivery`: sync to `FORGE_Module_Cargo`; the cargo module syncs
  to cargo objects
- `FORGE_Module_Hostage`: sync to `FORGE_Module_Hostages` and
  `FORGE_Module_Shooters`
- `FORGE_Module_HVT`: sync directly to HVT units
- `FORGE_Module_Defend`: configure the defense marker and wave settings; sync
  enemy units to use their groups as wave templates

These modules delegate to `fnc_startTask.sqf`.

### Start Through `fnc_startTask.sqf`
Use `fnc_startTask.sqf` for script-authored tasks. It registers task entities,
creates the BIS task, stores the catalog entry, and dispatches through
`fnc_handler.sqf`.

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

### Start Through The Handler
Use the handler when you want reputation gating and task ownership binding.
Create the BIS task and catalog entry separately if this task should appear in
the map task tab or CAD.

```sqf
["attack", ["task_attack_1", 1, 2, 1500000, -75, 375, false, false], 250, getPlayerUID player] call forge_server_task_fnc_handler;
["delivery", ["task_delivery_1", 1, 3, "delivery_zone", 250000, -75, 300, false, false, 900], 0, getPlayerUID player] call forge_server_task_fnc_handler;
```

Arguments:
- `0`: task type
- `1`: task-specific argument array
- `2`: minimum org reputation required to start the task
- `3`: requester UID used for ownership binding

### Start Task Functions Directly
Direct task calls still work, but they do not provide a requester UID. That means task ownership falls back to the `default` org.
Create the BIS task separately if this task should appear in the map task tab.

Use direct starts only when that behavior is intended, such as:
- mission-authored tasks
- editor-placed tasks
- server-owned/random tasks

If you want the accepting player's org to own the task rewards, use `fnc_handler.sqf` instead.

```sqf
["task_attack_1", 1, 2, 1500000, -75, 375, false, false] spawn forge_server_task_fnc_attack;
["task_hostage_1", 1, 2, "extract_marker", 1500000, -75, 500, [false, true], false, false] spawn forge_server_task_fnc_hostage;
```

## Event Hooks and Bus Integration
- `XEH_preInit.sqf`
  - compiles functions
  - initializes `TaskStore`
  - initializes task instance and entity controller classes
- `XEH_postInit.sqf`
  - registers task lifecycle event listeners with the event bus
  - handles task reward, notification, and rating events
  - syncs org and bank state through event bus listeners
  - registers the ACE defuse event hook

## Events Emitted
Task module emits the following events to the event bus:
- `task.created` - task instance created
- `task.started` - task execution started
- `task.completed` - task succeeded
- `task.failed` - task failed
- `task.cleared` - task cleaned up
- `task.reward.requested` - org rewards pending application
- `task.reward.applied` - org rewards applied
- `task.rating.applied` - player rating applied
- `task.notification.requested` - participant notifications pending dispatch

## Notes
- the dynamic mission manager in `fnc_missionManager.sqf` is initialized during task post-init; timer-based mission generation only runs when the `forge_server_task_enableGenerator` CBA setting is enabled
- CAD can request a specific generated mission type through `fnc_requestMissionTask.sqf`
- it starts server-owned tasks through `fnc_handler.sqf` and binds them to the `default` org
- task lifecycle for the mission manager is tracked through `TaskStore` status entries
- task backend state is intentionally transient and resets with the active server/mission lifecycle
- task rewards are org-owned, not player-owned
- participant notifications are sent through the notifications module, not through local server UI

## Authors
- J. Schmidt
- Creedcoder
- IDSolutions
