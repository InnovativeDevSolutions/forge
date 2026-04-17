# Forge Server CAD

## Overview
The CAD addon coordinates dispatch-facing operational state: groups,
assignments, dispatch orders, support requests, task assignment, permissions,
hydrate payloads, and recent activity.

CAD state is extension-backed but intentionally transient. It is scoped to the
active server or mission lifecycle and starts fresh after restart.

## Dependencies
- `forge_server_main`
- `forge_server_common`
- `forge_server_actor`
- `forge_server_org`
- `forge_server_task`
- `forge_server_extension` at runtime for CAD extension calls
- `forge_client_cad` and `forge_client_notifications` for response RPCs

## Main Components
- `fnc_initCadStore.sqf` coordinates repositories and request handling.
- `fnc_initActivityRepository.sqf` records recent CAD activity.
- `fnc_initAssignmentRepository.sqf` manages task assignments and dispatch
  orders.
- `fnc_initGroupRepository.sqf` manages group membership, role, and status.
- `fnc_initPermissionService.sqf` resolves dispatch permissions.
- `fnc_initPersistenceService.sqf` bridges SQF state to extension hot CAD
  storage.
- `fnc_initRequestRepository.sqf` manages support requests.

## Event Surface
The addon listens to and emits events through the event bus:

**Listens to:**
- Task lifecycle events (`task.started`, `task.completed`, `task.failed`)
- Task reward events to sync assignments
- Client notification/sync request events

**Emits:**
- `cad.assignment.assigned` - task assigned to group
- `cad.assignment.created` - new assignment created
- `cad.assignment.acknowledged` - assignment acknowledged
- `cad.assignment.declined` - assignment declined
- `cad.assignment.closed` - assignment completed
- `cad.request.submitted` - support request submitted
- `cad.request.closed` - support request resolved
- `cad.group.updated` - group status updated

Successful mutations may invalidate CAD state globally so clients refresh their views.

## Notes
CAD hydrate payloads include active task catalog entries from `TaskStore` and
organization context from `ActorStore`.
