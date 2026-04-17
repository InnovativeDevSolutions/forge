# Task Object Prototypes

This folder contains review-only `createHashMapObject` prototypes for task
instances. Their source now lives under `functions/prototypes/`, and they are
loaded for review with `[] call forge_server_task_fnc_initPrototypes;`.

Current prototypes:
- `TaskInstanceBaseClass`
- `EntityControllerBaseClass`
- `TargetEntityController`
- `ShooterEntityController`
- `AttackTaskBaseClass`
- `HostageTaskBaseClass`
- `HostageEntityController`
- `HVTEntityController`
- `CargoEntityController`
- `ProtectedEntityController`
- `IEDEntityController`
- `DefenseEnemyController`
- `DefuseTaskBaseClass`
- `DestroyTaskBaseClass`
- `DeliveryTaskBaseClass`
- `HVTTaskBaseClass`
- `DefendTaskBaseClass`

Review entry points:
- [taskObjectPrototypes.sqf](./taskObjectPrototypes.sqf)
- [fnc_initPrototypes.sqf](../functions/prototypes/fnc_initPrototypes.sqf)
- [fnc_TaskInstanceBaseClass.sqf](../functions/prototypes/fnc_TaskInstanceBaseClass.sqf)
- [fnc_EntityControllerBaseClass.sqf](../functions/prototypes/fnc_EntityControllerBaseClass.sqf)
- [fnc_TargetEntityController.sqf](../functions/prototypes/fnc_TargetEntityController.sqf)
- [fnc_ShooterEntityController.sqf](../functions/prototypes/fnc_ShooterEntityController.sqf)
- [fnc_AttackTaskBaseClass.sqf](../functions/prototypes/fnc_AttackTaskBaseClass.sqf)
- [fnc_HostageTaskBaseClass.sqf](../functions/prototypes/fnc_HostageTaskBaseClass.sqf)
- [fnc_HostageEntityController.sqf](../functions/prototypes/fnc_HostageEntityController.sqf)
- [fnc_HVTEntityController.sqf](../functions/prototypes/fnc_HVTEntityController.sqf)
- [fnc_CargoEntityController.sqf](../functions/prototypes/fnc_CargoEntityController.sqf)
- [fnc_ProtectedEntityController.sqf](../functions/prototypes/fnc_ProtectedEntityController.sqf)
- [fnc_IEDEntityController.sqf](../functions/prototypes/fnc_IEDEntityController.sqf)
- [fnc_DefenseEnemyController.sqf](../functions/prototypes/fnc_DefenseEnemyController.sqf)
- [fnc_DefuseTaskBaseClass.sqf](../functions/prototypes/fnc_DefuseTaskBaseClass.sqf)
- [fnc_DestroyTaskBaseClass.sqf](../functions/prototypes/fnc_DestroyTaskBaseClass.sqf)
- [fnc_DeliveryTaskBaseClass.sqf](../functions/prototypes/fnc_DeliveryTaskBaseClass.sqf)
- [fnc_HVTTaskBaseClass.sqf](../functions/prototypes/fnc_HVTTaskBaseClass.sqf)
- [fnc_DefendTaskBaseClass.sqf](../functions/prototypes/fnc_DefendTaskBaseClass.sqf)

Purpose:
- show what per-task instance objects could look like
- show what per-entity heartbeat/controller objects could look like
- separate state ownership from the current long procedural functions
- avoid committing the live addon to a large refactor before the model is
  reviewed
- keep shared lifecycle and reward initialization in `TaskInstanceBaseClass`
  so concrete task prototypes only define task-specific state
- keep heartbeat-style AI/object behavior in separate entity controllers instead
  of mixing it into task outcome loops

Important design choice:
- these prototypes use explicit `markSucceeded`, `markFailed`, and `cleanup`
  methods instead of relying on `#delete`
- task loops that use `sleep` or `waitUntil` with `sleep` must be started from
  scheduled code, typically via `spawn`

That is intentional. `createHashMapObject` destructor timing is reference-based,
so `#delete` is not a good primitive for mission-critical task completion or
reward flow.
