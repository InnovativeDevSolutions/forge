# Task Objects

This folder documents the active `createHashMapObject` task instances and entity
controllers. Their source lives under `functions/objects/`, and each class is
initialized directly from `XEH_preInit.sqf`.

Current task objects:
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

Source entry points:
- [fnc_TaskInstanceBaseClass.sqf](./fnc_TaskInstanceBaseClass.sqf)
- [fnc_EntityControllerBaseClass.sqf](./fnc_EntityControllerBaseClass.sqf)
- [fnc_TargetEntityController.sqf](./fnc_TargetEntityController.sqf)
- [fnc_ShooterEntityController.sqf](./fnc_ShooterEntityController.sqf)
- [fnc_AttackTaskBaseClass.sqf](./fnc_AttackTaskBaseClass.sqf)
- [fnc_HostageTaskBaseClass.sqf](./fnc_HostageTaskBaseClass.sqf)
- [fnc_HostageEntityController.sqf](./fnc_HostageEntityController.sqf)
- [fnc_HVTEntityController.sqf](./fnc_HVTEntityController.sqf)
- [fnc_CargoEntityController.sqf](./fnc_CargoEntityController.sqf)
- [fnc_ProtectedEntityController.sqf](./fnc_ProtectedEntityController.sqf)
- [fnc_IEDEntityController.sqf](./fnc_IEDEntityController.sqf)
- [fnc_DefenseEnemyController.sqf](./fnc_DefenseEnemyController.sqf)
- [fnc_DefuseTaskBaseClass.sqf](./fnc_DefuseTaskBaseClass.sqf)
- [fnc_DestroyTaskBaseClass.sqf](./fnc_DestroyTaskBaseClass.sqf)
- [fnc_DeliveryTaskBaseClass.sqf](./fnc_DeliveryTaskBaseClass.sqf)
- [fnc_HVTTaskBaseClass.sqf](./fnc_HVTTaskBaseClass.sqf)
- [fnc_DefendTaskBaseClass.sqf](./fnc_DefendTaskBaseClass.sqf)

Purpose:
- keep per-task instance state in task objects
- keep per-entity behavior in controller objects
- separate state ownership from long procedural function flows
- keep shared lifecycle and reward initialization in `TaskInstanceBaseClass`
- so concrete task objects only define task-specific state
- keep heartbeat-style AI/object behavior in separate entity controllers instead
  of mixing it into task outcome loops

Important design choice:
- these objects use explicit `markSucceeded`, `markFailed`, and `cleanup`
  methods instead of relying on `#delete`
- task loops that use `sleep` or `waitUntil` with `sleep` must be started from
  scheduled code, typically via `spawn`

That is intentional. `createHashMapObject` destructor timing is reference-based,
so `#delete` is not a good primitive for mission-critical task completion or
reward flow.
