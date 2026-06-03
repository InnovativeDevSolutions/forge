# Custom Mission Generators

Forge can be used as a complete out-of-box PMC mission framework, or as a
foundation that communities build on top of. Custom mission generators should
integrate through the same task, CAD, and event surfaces that the built-in
mission manager uses.

This guide documents the supported integration path for custom generators,
including the provider registry used by CAD/manual generated task requests.

## Recommended Architecture

Keep custom generation split into three layers:

| Layer | Responsibility |
| --- | --- |
| Generator | Select a mission type, position, entities, rewards, timing, and ownership metadata. |
| Task registration | Create a CAD-visible Forge task catalog entry and BIS map task. |
| Mission runtime | Own custom win/loss logic, cleanup, and task status transitions. |

Use Forge systems for persistence-adjacent state, dispatch visibility, group
assignment, notifications, ownership, rewards, and client refresh behavior.
Keep mission-specific spawning and objective logic in the mission or community
addon.

## Disable Built-In Generation

The built-in timer-driven generator is controlled by the server CBA setting:

```sqf
forge_server_task_enableGenerator = false;
```

When disabled, Forge does not run timer-based generated missions and CAD
hydrates no built-in generated task types.

This does not prevent custom code from creating CAD-visible tasks directly or
from serving CAD/manual generated task requests through a registered custom
provider.

The mission setup UI does not override this setting. Generated mission
enablement for the built-in provider is mission/server policy and stays in CBA
settings.

The mission setup UI can capture a generator provider preference:

- `builtin` for Forge's built-in generated mission provider
- `custom` for mission/community-owned generated mission providers

That preference is stored in `forge_server_task_generatorProvider` and mirrored
inside `forge_server_task_missionSetup_settings`. It is intentionally separate
from `forge_server_task_enableGenerator`; the CBA setting only gates Forge's
built-in provider. A registered custom provider can still publish generated task
types and handle CAD/manual requests when selected.

## Framework Mission Setup UI

Forge includes an optional framework-level mission setup UI in
`arma/client/addons/mission_setup`. Enable it with the server CBA setting:

```sqf
forge_server_task_enableMissionSetup = true;
```

When enabled, the UI opens for the setup operator before the mission manager
starts. By default, the operator is the player whose Eden variable name is
`ceo`. Missions can override the allowed unit variable names before client
post-init completes:

```sqf
missionNamespace setVariable [
    "forge_server_task_missionSetup_allowedUnitVariables",
    ["ceo", "mission_admin"],
    true
];
```

The UI configures:

- opposing faction
- generator provider preference
- max concurrent generated missions
- mission interval
- location reuse cooldown
- funds, reputation, penalty, and time limit ranges

Applying the UI writes framework-prefixed setup state:

```sqf
forge_server_task_missionSetup_settings
forge_server_task_missionSetup_settingsApplied
```

The server also publishes the selected opposing faction and side for generated
mission runtime code:

```sqf
ENEMY_FACTION_STR
ENEMY_SIDE
```

When settings are applied, Forge emits the EventBus event
`mission.setup.applied` with the applied settings in the event payload.

The mission manager waits until setup settings are applied. There is no timeout
fallback. If the operator presses Cancel, X, or Escape, Forge applies default
settings from CBA, mission parameters, and `CfgMissions`, then starts normally.

After setup settings have been applied, the setup UI cannot be reopened. The
actor interaction entry is hidden once clients receive the public applied flag,
and direct or stale open requests receive a notification explaining that setup
has already been applied.

## Provider Registry

Custom providers register on the server through the server-side CBA event:

```sqf
[
    "forge_server_task_registerMissionGeneratorProvider",
    ["custom", _provider]
] call CBA_fnc_serverEvent;
```

This event is intentionally fire-and-forget. The task module validates provider
shape server-side and logs registration failures.

The provider is a hashMap/hashMapObject with two required methods:

| Method | Arguments | Return |
| --- | --- | --- |
| `getGeneratedTaskTypes` | none | Array of hashMaps with `value` and `label` |
| `requestMissionTask` | `_taskType`, `_metadata`, `_requesterUid` | Result hashMap |

The request result should include:

| Key | Type | Notes |
| --- | --- | --- |
| `success` | Boolean | `true` when a task was generated |
| `message` | String | User-facing CAD response |
| `taskID` | String | Created task ID, or empty on failure |
| `taskType` | String | Resolved generated task type |

Example provider:

```sqf
private _provider = createHashMapObject [[
    ["#type", "CommunityMissionGeneratorProvider"],
    ["getGeneratedTaskTypes", {
        [
            createHashMapFromArray [["value", "pvp_hold"], ["label", "PvP Hold Area"]],
            createHashMapFromArray [["value", "supply_drop"], ["label", "Supply Drop"]]
        ]
    }],
    ["requestMissionTask", {
        params ["_taskType", "_metadata", "_requesterUid"];

        private _taskID = format ["custom_%1_%2", _taskType, floor random 100000];

        // Create/spawn the mission here, then publish it through Forge's task
        // catalog/status contract so CAD can assign and track it.

        createHashMapFromArray [
            ["success", true],
            ["message", format ["Generated custom %1 task %2.", _taskType, _taskID]],
            ["taskID", _taskID],
            ["taskType", _taskType]
        ]
    }]
]];

[
    "forge_server_task_registerMissionGeneratorProvider",
    ["custom", _provider]
] call CBA_fnc_serverEvent;
```

When the setup UI provider toggle is set to `custom`, CAD hydrates task types
from the registered `custom` provider and CAD/manual requests call that
provider's `requestMissionTask` method. If no custom provider is registered,
Forge logs a warning and falls back to the built-in provider.

## CAD-Visible Task Contract

CAD reads assignable contracts from `TaskStore.getActiveTaskCatalog`. A custom
task appears in CAD when it has:

- a task catalog entry
- a task status of `available`, `assigned`, or `active`
- a stable `taskID` or `taskId`
- display fields such as `title`, `description`, `type`, and `position`

The easiest supported path is to call `forge_server_task_fnc_startTask` from
server-side mission code:

```sqf
[
    "attack",
    "custom_attack_01",
    getMarkerPos "custom_attack_area",
    "Raid the Checkpoint",
    "Clear the checkpoint and secure the site.",
    createHashMapFromArray [
        ["targets", [target_1, target_2, target_3]]
    ],
    createHashMapFromArray [
        ["limitSuccess", 3],
        ["limitFail", 0],
        ["funds", 25000],
        ["ratingSuccess", 10],
        ["ratingFail", -5],
        ["timeLimit", 1200]
    ],
    0,
    "",
    "custom_generator"
] call forge_server_task_fnc_startTask;
```

`startTask` registers entities, creates the BIS task, upserts the Forge task
catalog entry, sets the initial task status, and dispatches the matching Forge
task flow.

## Custom Runtime Tasks

If a community generator has its own objective logic and does not use a built-in
Forge task flow, register the catalog entry and status directly:

```sqf
private _taskID = "pvp_supply_drop_01";
private _entry = createHashMapFromArray [
    ["taskID", _taskID],
    ["taskId", _taskID],
    ["type", "pvp_supply_drop"],
    ["taskType", "custom"],
    ["title", "Contest the Supply Drop"],
    ["description", "Secure the marked drop zone before the opposing team."],
    ["position", getMarkerPos "supply_drop_zone"],
    ["accepted", false],
    ["requesterUid", ""],
    ["orgID", "default"],
    ["source", "custom_generator"]
];

"forge_server" callExtension ["task:catalog:upsert", [
    _taskID,
    toJSON _entry
]];

"forge_server" callExtension ["task:status:set", [
    _taskID,
    "available"
]];
```

Create a BIS task separately if players should see it in the vanilla map task
tab:

```sqf
[
    west,
    _taskID,
    ["Secure the supply drop.", "Supply Drop", "custom"],
    getMarkerPos "supply_drop_zone",
    "CREATED",
    1,
    true,
    "container"
] call BIS_fnc_taskCreate;
```

When custom objective logic completes, set the task status:

```sqf
"forge_server" callExtension ["task:status:set", [_taskID, "succeeded"]];
// or
"forge_server" callExtension ["task:status:set", [_taskID, "failed"]];
```

Use `task:clear` or `task:catalog:delete` when the custom runtime fully owns
cleanup and the contract should leave CAD.

## CAD Assignment Lifecycle

CAD assignment and task execution are intentionally separate.

| Phase | Task status | Owner |
| --- | --- | --- |
| Created and visible | `available` | No group reservation yet. |
| Dispatcher assigns | `assigned` | CAD reserves the task for a group. |
| Group leader acknowledges | `active` | Task ownership is accepted for the acknowledging player/org. |
| Runtime finishes | `succeeded` or `failed` | CAD refreshes and removes completed active contracts. |

Custom task logic should account for this lifecycle. If the task should not
start until the assigned group leader accepts it, wait for `active` status:

```sqf
waitUntil {
    sleep 2;
    private _statusResult = "forge_server" callExtension ["task:status:get", [_taskID]];
    private _status = fromJSON (_statusResult select 0);
    _status isEqualTo "active"
};
```

If a group declines the assignment, CAD returns the task to `available`.

## EventBus Integration

The server EventBus is an in-process SQF event system. Initialize it if needed:

```sqf
if (isNil "forge_server_common_EventBus") then {
    call forge_server_common_fnc_eventBus;
};
```

Subscribe to CAD and task lifecycle events:

```sqf
private _token = forge_server_common_EventBus call ["on", [
    "cad.assignment.acknowledged",
    {
        params ["_event"];
        private _taskID = _event getOrDefault ["taskID", ""];
        private _assignment = _event getOrDefault ["assignment", createHashMap];
        diag_log format [
            "[CustomGenerator] Task %1 acknowledged by group %2",
            _taskID,
            _assignment getOrDefault ["groupId", ""]
        ];
    },
    "custom_generator.assignment"
]];
```

Remove a listener when it is no longer needed:

```sqf
forge_server_common_EventBus call ["off", [_token]];
```

Useful CAD events:

| Event | When it fires |
| --- | --- |
| `cad.assignment.assigned` | Dispatcher assigns a task or order. |
| `cad.assignment.acknowledged` | Group leader accepts an assignment. |
| `cad.assignment.declined` | Group leader declines an assignment. |
| `cad.assignment.closed` | Dispatch order is closed. |
| `cad.request.submitted` | Support request is submitted. |
| `cad.request.closed` | Support request is closed. |
| `cad.group.updated` | Group status or role changes. |

Useful task events:

| Event | When it fires |
| --- | --- |
| `task.created` | Task catalog entry is registered through TaskStore. |
| `task.started` | Task status transitions to active/started. |
| `task.completed` | Task succeeds. |
| `task.failed` | Task fails. |
| `task.cleared` | Task state is cleared. |
| `task.reward.applied` | Task reward mutation succeeds. |
| `task.rating.applied` | Rating/earnings outcome succeeds. |
| `task.notification.requested` | Task participant notification is requested. |

CAD already listens to task and CAD events and globally invalidates CAD state
when relevant changes occur. Custom generators usually only need to emit task
status changes through TaskStore or extension commands; CAD refresh follows
from the existing listeners.

## Generated Task Provider Behavior

CAD hydrates generated task types and requests generated tasks through the task
provider registry. The selected provider comes from
`forge_server_task_generatorProvider`, defaulting to `builtin`.

Use one of these supported patterns:

1. Register a custom provider so CAD/manual generated task requests route to
   community code.
2. Run custom generators from mission/server code and create CAD-visible tasks
   directly.
3. Use CAD support requests or dispatch orders to let players request custom
   work, then have mission code convert approved requests into tasks.
4. Keep the built-in generator enabled only if the community intentionally
   wants the framework dropdown and request handler.

## Provider Extension Details

The implemented provider shape is intentionally small:

- built-in Forge provider remains the default out-of-box behavior
- mission/community providers can supply their own `generatedTaskTypes`
- mission/community providers can handle generated-task requests
- disabling the built-in provider does not disable custom providers
- mission designers or developers can select or toggle the active provider from
  the framework mission setup UI when a mission includes custom generators

## Validation Checklist

For each custom generator:

1. Disable the built-in generator if it should not run.
2. Generate or place task entities on the server.
3. Register a task catalog entry with stable `taskID` and display fields.
4. Set task status to `available`.
5. Confirm the task appears in CAD.
6. Assign it to a group from CAD.
7. Acknowledge and decline from the group leader UI.
8. Confirm custom logic waits for `active` if needed.
9. Set `succeeded` or `failed` when the objective resolves.
10. Confirm CAD refreshes and rewards or cleanup behave as expected.
