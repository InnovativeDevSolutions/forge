#include "..\script_component.hpp"

/*
 * Review-only prototype initializer for object-based task instances.
 *
 * Usage in debug/testing:
 * private _prototypes = [] call FUNC(initPrototypes);
 *
 * private _task = createHashMapObject [
 *     _prototypes get "HostageTaskBaseClass",
 *     [
 *         "task_hostage_review",
 *         createHashMapFromArray [
 *             ["hostages", [hostage1, hostage2]],
 *             ["shooters", [shooter1, shooter2]]
 *         ],
 *         createHashMapFromArray [
 *             ["extractionZone", "hostage_extract"],
 *             ["limitSuccess", 2],
 *             ["limitFail", 1],
 *             ["execution", true],
 *             ["timeLimit", 900]
 *         ]
 *     ]
 * ];
 */

[] call FUNC(TaskInstanceBaseClass);
[] call FUNC(EntityControllerBaseClass);
[] call FUNC(AttackTaskBaseClass);
[] call FUNC(HostageTaskBaseClass);
[] call FUNC(HostageEntityController);
[] call FUNC(TargetEntityController);
[] call FUNC(ShooterEntityController);
[] call FUNC(HVTEntityController);
[] call FUNC(CargoEntityController);
[] call FUNC(ProtectedEntityController);
[] call FUNC(IEDEntityController);
[] call FUNC(DefenseEnemyController);
[] call FUNC(DefuseTaskBaseClass);
[] call FUNC(DestroyTaskBaseClass);
[] call FUNC(DeliveryTaskBaseClass);
[] call FUNC(HVTTaskBaseClass);
[] call FUNC(DefendTaskBaseClass);

createHashMapFromArray [
    ["TaskInstanceBaseClass", GVAR(TaskInstanceBaseClass)],
    ["EntityControllerBaseClass", GVAR(EntityControllerBaseClass)],
    ["AttackTaskBaseClass", GVAR(AttackTaskBaseClass)],
    ["HostageTaskBaseClass", GVAR(HostageTaskBaseClass)],
    ["HostageEntityController", GVAR(HostageEntityController)],
    ["TargetEntityController", GVAR(TargetEntityController)],
    ["ShooterEntityController", GVAR(ShooterEntityController)],
    ["HVTEntityController", GVAR(HVTEntityController)],
    ["CargoEntityController", GVAR(CargoEntityController)],
    ["ProtectedEntityController", GVAR(ProtectedEntityController)],
    ["IEDEntityController", GVAR(IEDEntityController)],
    ["DefenseEnemyController", GVAR(DefenseEnemyController)],
    ["DefuseTaskBaseClass", GVAR(DefuseTaskBaseClass)],
    ["DestroyTaskBaseClass", GVAR(DestroyTaskBaseClass)],
    ["DeliveryTaskBaseClass", GVAR(DeliveryTaskBaseClass)],
    ["HVTTaskBaseClass", GVAR(HVTTaskBaseClass)],
    ["DefendTaskBaseClass", GVAR(DefendTaskBaseClass)]
]
