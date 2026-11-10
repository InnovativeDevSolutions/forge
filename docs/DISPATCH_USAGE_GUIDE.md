# Dispatch Usage Guide

The dispatch addon (`forge_server_dispatch`) adds dispatcher tooling on top of
[CAD](./CAD_USAGE_GUIDE.md):

- dispatch orders
- support requests
- the activity feed
- generated mission requests

It is optional. Without it, CAD still handles contracts, assignment,
accept/decline and groups, and the CAD UI hides the dispatch controls.

Requests and activity are transient extension state that resets with the
server or mission.

## Dispatch Orders

A dispatch order ("Backup <group>") asks one group to back up another. It is a
task catalog entry with:

| Field | Value |
| --- | --- |
| `taskID` | `dispatch-order:<n>` |
| `source` | `dispatch` |
| `type`, `taskType` | `dispatch_order` |
| `targetGroupId`, `targetGroupCallsign` | The group to back up. |
| `priority` | `routine`, `priority` or `emergency`. |
| `requestId`, `requestType`, `requestTitle`, `requestSummary` | Set when the order was created from a support request. |

Creating an order registers the entry and assigns it to the chosen group
through CAD, so it follows the normal accept/decline flow. No task handler
runs for an order. Its position follows the target group on every CAD
refresh.

Closing an order (dispatchers only) marks it `succeeded` if it was accepted,
sets the BIS task state, and clears it from the catalog.

```sqf
forge_server_dispatch_DispatchStore call ["createOrder", [
    _dispatcherUid, _assigneeGroupID, _targetGroupID, "Hold the east side.", "emergency", createHashMap
]];
forge_server_dispatch_DispatchStore call ["closeOrder", [_dispatcherUid, "dispatch-order:1"]];
```

## Support Requests

Group leaders submit structured requests. A dispatcher or the submitting
group's leader can close them.

| Type | Label |
| --- | --- |
| `medevac_9line` | 9-Line MEDEVAC |
| `ace_lace` | ACE/LACE |
| `fire_support` | Fire Support |
| `air_support` | Air Support |
| `logreq` | LOGREQ |

The server fills in the group, callsign, position and time, and builds a title
and summary from the fields. Unknown priorities become `priority`.

```sqf
private _fields = createHashMapFromArray [
    ["pickup_location", "Grid 123456"],
    ["precedence", "urgent"],
    ["security", "secure"]
];
forge_server_dispatch_DispatchStore call ["submitRequest", [getPlayerUID player, "medevac_9line", _fields, "emergency"]];
```

## Activity Feed

The feed is written from events: contract assigned, accepted and declined,
group updates, task success or failure, order closed, and requests submitted
or closed. The last 50 entries are sent to CAD.

## Generated Missions

Dispatchers can request a generated task. The request goes to the task
provider registry; see [Custom Mission Generators](./CUSTOM_MISSION_GENERATORS.md).
Built-in generation is controlled by `forge_server_task_enableGenerator`.

## Server RPCs

| Event | Arguments | Response |
| --- | --- | --- |
| `forge_server_dispatch_requestCreateOrder` | `uid`, `assigneeGroupID`, `targetGroupID`, `note`, `priority`, `request` | `forge_client_cad_responseCadAssignment` |
| `forge_server_dispatch_requestCloseOrder` | `uid`, `taskID` | `forge_client_cad_responseCadAssignment` |
| `forge_server_dispatch_requestSubmitSupportRequest` | `uid`, `type`, `fields`, `priority` | `forge_client_cad_responseCadRequest` |
| `forge_server_dispatch_requestCloseSupportRequest` | `uid`, `requestID` | `forge_client_cad_responseCadRequest` |
| `forge_server_dispatch_requestGeneratedMission` | `uid`, `taskType`, `metadata` | `forge_client_cad_responseCadRequest` |

## Events

| Event | When it fires |
| --- | --- |
| `dispatch.order.created` | An order is created and assigned. |
| `dispatch.order.closed` | An order is closed. |
| `dispatch.request.submitted` | A support request is submitted. |
| `dispatch.request.closed` | A support request is closed. |

## CAD Payload

The addon registers the `dispatch` hydrate contributor, which sets
`dispatchEnabled = true` and adds `requests` (dispatchers see all, others
their group's), `activity`, and `generatedTaskTypes` (dispatchers only).

## Extension Commands

| Command | Arguments | Returns |
| --- | --- | --- |
| `dispatch:requests:list` | none | Open requests, newest first. |
| `dispatch:requests:get` | `request_id` | Request JSON or `null`. |
| `dispatch:requests:submit` | `request_seed_json` | `{request, message}`. |
| `dispatch:requests:close` | `request_id` | `{request, message}` and removes the request. |
| `dispatch:activity:append` | `entry_json` | `OK`. |
| `dispatch:activity:recent` | `limit` | Recent entries, oldest first (max 200). |
