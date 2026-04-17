#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Initializes the defuse module
 *
 * Arguments:
 * 0: Logic <OBJECT> - The logic object
 * 1: Units <ARRAY> - The array of units
 * 2: Activated <BOOL> - Whether the module is activated
 *
 * Return Value:
 * None
 *
 * Example:
 * [logicObject, [unit1, unit2], true] call forge_server_task_fnc_defuseModule;
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_units", [], [[]]], ["_activated", true, [true]]];

if !(_activated) exitWith {};

private _taskID = _logic getVariable ["TaskID", ""];
if (_taskID isEqualTo "") exitWith {
    ["ERROR", "Defuse module: no task ID configured."] call EFUNC(common,log);
};

private _syncedModules = synchronizedObjects _logic;
private _iedModule = (_syncedModules select { typeOf _x isEqualTo "FORGE_Module_Explosives" }) param [0, objNull];
private _protectedModule = (_syncedModules select { typeOf _x isEqualTo "FORGE_Module_Protected" }) param [0, objNull];
private _iedEntities = if (!isNull _iedModule) then {
    synchronizedObjects _iedModule select { !(_x isKindOf "Logic") }
} else {
    []
};
private _protectedEntities = if (!isNull _protectedModule) then {
    synchronizedObjects _protectedModule select { !(_x isKindOf "Logic") }
} else {
    []
};

["INFO", format [
    "Defuse Module: TaskID: %1, IEDs: %2, Protected: %3, IED timer: %4s",
    _taskID, count _iedEntities, count _protectedEntities,
    _logic getVariable ["TimeLimit", 300]
]] call EFUNC(common,log);

private _taskPos = if (_iedEntities isNotEqualTo []) then {
    getPosATL (_iedEntities select 0)
} else {
    getPosATL _logic
};

private _equipmentRewards = [_logic getVariable ["EquipmentRewards", "[]"], _taskID, "equipment"] call FUNC(parseRewards);
private _supplyRewards = [_logic getVariable ["SupplyRewards", "[]"], _taskID, "supplies"] call FUNC(parseRewards);
private _weaponRewards = [_logic getVariable ["WeaponRewards", "[]"], _taskID, "weapons"] call FUNC(parseRewards);
private _vehicleRewards = [_logic getVariable ["VehicleRewards", "[]"], _taskID, "vehicles"] call FUNC(parseRewards);
private _specialRewards = [_logic getVariable ["SpecialRewards", "[]"], _taskID, "special"] call FUNC(parseRewards);

[
    "defuse",
    _taskID,
    _taskPos,
    format ["Defuse: %1", _taskID],
    "Locate and defuse all explosive devices before they detonate.",
    createHashMapFromArray [
        ["ieds", _iedEntities],
        ["protected", _protectedEntities]
    ],
    createHashMapFromArray [
        ["limitFail", _logic getVariable ["LimitFail", -1]],
        ["limitSuccess", _logic getVariable ["LimitSuccess", -1]],
        ["funds", _logic getVariable ["CompanyFunds", 0]],
        ["ratingFail", _logic getVariable ["RatingFail", 0]],
        ["ratingSuccess", _logic getVariable ["RatingSuccess", 0]],
        ["endSuccess", _logic getVariable ["EndSuccess", false]],
        ["endFail", _logic getVariable ["EndFail", false]],
        ["iedTimer", _logic getVariable ["TimeLimit", 300]],
        ["equipment", _equipmentRewards],
        ["supplies", _supplyRewards],
        ["weapons", _weaponRewards],
        ["vehicles", _vehicleRewards],
        ["special", _specialRewards]
    ]
] call FUNC(startTask);

deleteVehicle _logic;
