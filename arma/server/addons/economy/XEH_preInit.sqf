#include "script_component.hpp"

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

// private _category = [QUOTE(MOD_NAME), LLSTRING(displayName)];

if (isNil QGVAR(MEconomyStore)) then { call FUNC(initMEconomyStore); };
if (isNil QGVAR(FEconomyStore)) then { call FUNC(initFEconomyStore); };
if (isNil QGVAR(SEconomyStore)) then { call FUNC(initSEconomyStore); };

[QGVAR(FuelStart), {
    params ["_source", "_target", "_unit"];
    GVAR(FEconomyStore) call ["start", [_source, _target, _unit]];
}] call CFUNC(addEventHandler);

[QGVAR(FuelTick), {
    params ["_source", "_target", "_amount"];

    private _liters = GETVAR(_target,liters,0);
    private _newLiters = _liters + _amount;
    SETVAR(_target,liters,_newLiters);
}] call CFUNC(addEventHandler);

[QGVAR(FuelStop), {
    params ["_source", "_target"];
    GVAR(FEconomyStore) call ["stop", [_source, _target]];
}] call CFUNC(addEventHandler);

[QGVAR(RepairService), {
    params ["_target", "_unit", ["_cost", -1, [0]]];
    GVAR(SEconomyStore) call ["repair", [_target, _unit, _cost]];
}] call CFUNC(addEventHandler);

[QGVAR(RearmService), {
    params ["_target", "_unit", ["_cost", -1, [0]]];
    GVAR(SEconomyStore) call ["rearm", [_target, _unit, _cost]];
}] call CFUNC(addEventHandler);

[QGVAR(RefuelService), {
    params ["_target", "_unit"];
    GVAR(FEconomyStore) call ["refuel", [_target, _unit]];
}] call CFUNC(addEventHandler);

[QGVAR(onKilled), {
    params ["_unit"];
    GVAR(MEconomyStore) call ["onKilled", [_unit]];
}] call CFUNC(addEventHandler);

[QGVAR(onRespawn), {
    params ["_unit", "_corpse", "_uid"];
    GVAR(MEconomyStore) call ["onRespawn", [_unit, _corpse, _uid]];
}] call CFUNC(addEventHandler);

[QGVAR(onHealed), {
    params ["_unit"];
    GVAR(MEconomyStore) call ["onHealed", [_unit]];
}] call CFUNC(addEventHandler);
