# CAD Usage Guide

CAD (`forge_server_cad`) answers four questions:

- which contracts are available
- which group each contract is assigned to
- whether that group accepted or declined it
- each group's role, status and members

CAD keeps no contract state of its own. Contracts are task catalog entries and
`TaskStore` owns their lifecycle. Dispatch orders, support requests, the
activity feed and generated mission requests live in the optional
[Dispatch addon](./DISPATCH_USAGE_GUIDE.md).

## Contract Lifecycle

```
available --assign (dispatcher)--> assigned --accept (group leader)--> active
                                   assigned --decline (group leader)--> available
```

| Step | Who | Effect |
| --- | --- | --- |
| Assign | Dispatcher | Task must be `available`. Sets `assignedGroupId`, `assignedGroupCallsign`, `assignedByUid` and moves the task to `assigned`. The group leader is notified. |
| Accept | Leader of the assigned group | Task must be `assigned`. Binds task ownership to the leader and their organization and moves the task to `active`, which starts task logic. The dispatcher is notified. |
| Decline | Leader of the assigned group | Task must be `assigned`. Clears the assignment, records `lastDeclinedGroupId`, `lastDeclinedGroupCallsign`, `lastDeclinedByUid` and `lastDeclinedAt`, and returns the task to `available`. The dispatcher is notified. |

An accepted (`active`) contract cannot be declined.

Task logic for Eden and mission-manager tasks waits until the task is `active`,
so nothing spawns before a group accepts.

## Groups

CAD tracks player groups on the configured sides (default `[west]`). Each
group gets a stable ID (`grp:<n>`) stored on the group object, so the ID and
the group's role and status survive leader changes.

```sqf
// Track BLUFOR and independent groups.
missionNamespace setVariable ["forge_server_cad_sides", [west, independent]];
```

Valid statuses: `available`, `en_route`, `on_task`, `holding`, `danger`,
`unavailable`. Valid roles: `infantry`, `recon`, `armor`, `air`, `logistics`,
`support`. The group leader or a dispatcher can change them.

## Permissions

`canDispatch` is true for the owner of the player's organization, or for a
player whose unit variable name is `ceo` or `dispatch` in the `default`
organization.

## Server RPCs

The CAD client sends these CBA server events. Each takes the caller's UID
first.

| Event | Arguments | Response |
| --- | --- | --- |
| `forge_server_cad_requestHydrateCad` | `uid` | `forge_client_cad_responseHydrateCad` |
| `forge_server_cad_requestAssignCadContract` | `uid`, `taskID`, `groupID`, `note` | `forge_client_cad_responseCadAssignment` |
| `forge_server_cad_requestAcceptCadContract` | `uid`, `taskID` | `forge_client_cad_responseCadAssignment` |
| `forge_server_cad_requestDeclineCadContract` | `uid`, `taskID` | `forge_client_cad_responseCadAssignment` |
| `forge_server_cad_requestUpdateCadGroupProfile` | `uid`, `groupID`, `status`, `role` | `forge_client_cad_responseCadGroupUpdate` |

Pass an empty string for a status or role you are not changing. Successful
changes broadcast `forge_client_cad_invalidateCadState` so open CAD views
refresh.

## Server API

Server code can drive the same flow through the CAD store:

```sqf
// Dispatcher assigns task-123 to a group.
forge_server_cad_CadStore call ["assignContract", [_dispatcherUid, "task-123", _groupID, "Move to the objective."]];

// The group leader accepts or declines.
forge_server_cad_CadStore call ["acceptContract", [_leaderUid, "task-123"]];
forge_server_cad_CadStore call ["declineContract", [_leaderUid, "task-123"]];

// Look up a player's group and its record.
private _groupRepository = forge_server_cad_CadStore get "GroupRepository";
private _groupID = _groupRepository call ["getPlayerGroupId", [getPlayerUID _unit]];
private _group = _groupRepository call ["getGroupRecord", [_groupID]];
```

Each call returns a hashmap with `success` and `message`. The contract calls
also return the updated task catalog `entry`.

## Events

CAD emits these on the server EventBus. Contract events carry `taskId`,
`groupId` and the updated catalog `entry`.

| Event | When it fires |
| --- | --- |
| `cad.contract.assigned` | A dispatcher assigns a contract. |
| `cad.contract.accepted` | The assigned group leader accepts. |
| `cad.contract.declined` | The assigned group leader declines. |
| `cad.group.updated` | A group's role or status changes. |

CAD listens to `task.created`, `task.started`, `task.completed`,
`task.failed` and `task.cleared` to refresh open CAD views.

## Hydrate Payload

`buildHydratePayload` returns:

| Key | Contents |
| --- | --- |
| `groups` | Live groups: `groupId`, `callsign`, `leaderUid`, `leaderName`, `members`, `role`, `status`, `position`, `currentTaskId`, `currentTaskTitle`. |
| `contracts` | Active task catalog entries plus `assignedGroupId` and `assignmentState` (`unassigned`, `assigned`, `accepted`, or `active` for a task with no group). Dispatchers see every contract; other players only their group's. |
| `session` | `uid`, `orgId`, `isDispatcher`, `groupId`, `isLeader`. |
| `dispatchEnabled` | `false` unless the dispatch addon is loaded. |
| `requests`, `activity`, `generatedTaskTypes` | Empty unless the dispatch addon is loaded. |

### Adding sections

Other addons can add sections to the payload. The contributor gets
`[uid, session, payload]` and returns a hashmap that is merged in. It may also
update existing payload entries in place.

```sqf
forge_server_cad_CadStore call ["registerHydrateContributor", ["myAddon", {
    params ["_uid", "_session", "_payload"];
    createHashMapFromArray [["mySection", []]]
}]];
```

## Task Extension Commands

The contract steps are task extension commands, so the state checks run in
one place:

| Command | Arguments | Returns |
| --- | --- | --- |
| `task:group:assign` | `task_id`, `{groupId, groupCallsign, requesterUid, requesterName, note, timestamp}` | Mutation result with `status`, `entry`, `message`. |
| `task:group:accept` | `task_id`, `{groupId, requesterUid, requesterName, orgId, timestamp}` | Mutation result. |
| `task:group:decline` | `task_id`, `{groupId, requesterUid, requesterName, timestamp}` | Mutation result. |

Errors are returned as `Error: <message>`, for example
`Error: Task is not awaiting acceptance (status: active).` Prefer the
`TaskStore` methods (`assignTaskToGroup`, `acceptTaskForGroup`,
`declineTaskForGroup`) over calling these directly, because they also keep the
SQF runtime catalog and lifecycle events in step.

## Related Guides

- [Dispatch Usage Guide](./DISPATCH_USAGE_GUIDE.md)
- [Client CAD Usage Guide](./CLIENT_CAD_USAGE_GUIDE.md)
- [Task Usage Guide](./TASK_USAGE_GUIDE.md)
- [Custom Mission Generators](./CUSTOM_MISSION_GENERATORS.md)
