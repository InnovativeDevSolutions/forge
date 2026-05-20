#include "script_component.hpp"

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

private _category = [QUOTE(MOD_NAME), LLSTRING(displayName)];

#include "initSettings.inc.sqf"

[] call FUNC(TaskStateGateway);
[] call FUNC(TaskLifecycleReporter);
[] call FUNC(TaskCatalogStore);
[] call FUNC(TaskEntityRegistry);
[] call FUNC(TaskParticipantTracker);
[] call FUNC(TaskRewardService);
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

call FUNC(initTaskStore);
if !(isNil QGVAR(TaskStore)) then { GVAR(TaskStore) call ["resetMissionState", []]; };
