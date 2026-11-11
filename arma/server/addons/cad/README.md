# Forge Server CAD

## Overview
CAD answers four questions: which contracts exist, which group each is
assigned to, whether that group accepted or declined it, and what each group's
role, status and members are.

CAD keeps no contract state of its own. Contracts are task catalog entries and
`TaskStore` owns their lifecycle; CAD checks who may act and calls it.

```
available --assign (dispatcher)--> assigned --accept (group leader)--> active
                                   assigned --decline (group leader)--> available
```

An accepted (`active`) contract cannot be declined. A declined contract returns
to the board with `lastDeclinedGroupId`, `lastDeclinedGroupCallsign` and
`lastDeclinedAt` set on its catalog entry.

## Dependencies
- `forge_server_main`, `forge_server_common`, `forge_server_actor`,
  `forge_server_org`, `forge_server_task`
- `forge_client_cad` and `forge_client_notifications` for response RPCs

## Main Components
- `fnc_initCadStore.sqf` coordinates services, handles RPCs, builds the hydrate
  payload and hosts the hydrate contributor registry.
- `fnc_initContractService.sqf` assigns, accepts and declines contracts.
- `fnc_initGroupRepository.sqf` builds live groups (members, leader, role,
  status) and updates group profiles.
- `fnc_initPermissionService.sqf` resolves dispatcher permission.

## Groups
Every tracked group gets a stable ID (`grp:<n>`) stored on the group object,
so the ID and its role/status survive leader changes. Tracked sides default to
`[west]`; a mission can override them:

```sqf
missionNamespace setVariable ["forge_server_cad_sides", [west, independent]];
```

## RPCs
| Server event | Purpose |
| --- | --- |
| `forge_server_cad_requestHydrateCad` | Build the CAD payload for a player |
| `forge_server_cad_requestAssignCadContract` | Dispatcher assigns a contract to a group |
| `forge_server_cad_requestAcceptCadContract` | Group leader accepts the assigned contract |
| `forge_server_cad_requestDeclineCadContract` | Group leader declines the assigned contract |
| `forge_server_cad_requestUpdateCadGroupProfile` | Leader or dispatcher sets role and/or status |

## Events
Emits `cad.contract.assigned`, `cad.contract.accepted`,
`cad.contract.declined` and `cad.group.updated` on the event bus. Listens to
`task.*` lifecycle events to refresh open CAD views.

## Extending the hydrate payload
Other addons add sections to the CAD payload with a contributor. The code gets
`[uid, session, payload]` and returns a hashmap that is merged into the payload:

```sqf
forge_server_cad_CadStore call ["registerHydrateContributor", ["myAddon", {
    params ["_uid", "_session", "_payload"];
    createHashMapFromArray [["mySection", []]]
}]];
```

`forge_server_dispatch` uses this for support requests, the activity feed and
generated task types.
