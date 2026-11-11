# Forge Server Dispatch

## Overview
Dispatcher tooling on top of CAD. The addon is optional: without it, CAD still
handles contracts, assignment, accept/decline and groups.

- **Dispatch orders** ("Backup <group>"): task catalog entries with
  `source = "dispatch"` and `taskType = "dispatch_order"`. They go through the
  normal CAD assign/accept/decline flow. No task handler runs for them; a
  dispatcher closes them, which marks an accepted order succeeded and clears it.
- **Support requests**: 9-line MEDEVAC, ACE/LACE, fire support, air support and
  LOGREQ, submitted by group leaders and closed by a dispatcher or the leader.
- **Activity feed**: recent board activity, written from CAD, task and dispatch
  events.
- **Generated missions**: dispatchers request a generated task from the
  mission generator registry.

Requests and activity are transient extension state (`dispatch:*` routes).

## Dependencies
- `forge_server_main`, `forge_server_common`, `forge_server_actor`,
  `forge_server_task`, `forge_server_cad`

## RPCs
| Server event | Purpose |
| --- | --- |
| `forge_server_dispatch_requestCreateOrder` | Create and assign a backup order |
| `forge_server_dispatch_requestCloseOrder` | Close a dispatch order |
| `forge_server_dispatch_requestSubmitSupportRequest` | Group leader submits a support request |
| `forge_server_dispatch_requestCloseSupportRequest` | Close a support request |
| `forge_server_dispatch_requestGeneratedMission` | Request a generated mission task |

Responses use the CAD client RPCs (`responseCadAssignment`,
`responseCadRequest`), so the CAD UI needs no extra handlers.

## Events
Emits `dispatch.order.created`, `dispatch.order.closed`,
`dispatch.request.submitted` and `dispatch.request.closed`.

## CAD payload
Registers the `dispatch` hydrate contributor, which adds `dispatchEnabled = true`,
`requests`, `activity` and `generatedTaskTypes` (dispatchers only), and
keeps each dispatch order's position on its target group.
