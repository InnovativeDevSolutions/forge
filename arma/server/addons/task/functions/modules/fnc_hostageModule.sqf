#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Initializes the hostage module
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
 * [logicObject, [unit1, unit2], true] call forge_server_task_fnc_hostageModule;
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_units", [], [[]]], ["_activated", true, [true]]];

if !(_activated) exitWith {};

private _taskID = _logic getVariable ["TaskID", ""];
if (_taskID isEqualTo "") exitWith {
    ["ERROR", "Hostage module: no task ID configured."] call EFUNC(common,log);
};

private _syncedModules = synchronizedObjects _logic;
private _hostageModule = (_syncedModules select { typeOf _x isEqualTo "FORGE_Module_Hostages" }) param [0, objNull];
private _shooterModule = (_syncedModules select { typeOf _x isEqualTo "FORGE_Module_Shooters" }) param [0, objNull];
private _hostageEntities = if (!isNull _hostageModule) then {
    synchronizedObjects _hostageModule select {
        (_x isKindOf "CAManBase") && { !(_x isKindOf "Logic") }
    }
} else {
    []
};
private _shooterEntities = if (!isNull _shooterModule) then {
    synchronizedObjects _shooterModule select {
        (_x isKindOf "CAManBase") && { !(_x isKindOf "Logic") }
    }
} else {
    []
};

["INFO", format [
    "Hostage Module: TaskID: %1, ExtZone: %2, Hostages: %3, Shooters: %4, CBRN: %5, Execution: %6",
    _taskID,
    _logic getVariable ["ExtZone", ""],
    count _hostageEntities,
    count _shooterEntities,
    _logic getVariable ["CBRN", false],
    _logic getVariable ["Execution", false]
]] call EFUNC(common,log);

private _taskPos = if (_hostageEntities isNotEqualTo []) then {
    getPosATL (_hostageEntities select 0)
} else {
    getPosATL _logic
};

private _equipmentRewards = [_logic getVariable ["EquipmentRewards", "[]"], _taskID, "equipment"] call FUNC(parseRewards);
private _supplyRewards = [_logic getVariable ["SupplyRewards", "[]"], _taskID, "supplies"] call FUNC(parseRewards);
private _weaponRewards = [_logic getVariable ["WeaponRewards", "[]"], _taskID, "weapons"] call FUNC(parseRewards);
private _vehicleRewards = [_logic getVariable ["VehicleRewards", "[]"], _taskID, "vehicles"] call FUNC(parseRewards);
private _specialRewards = [_logic getVariable ["SpecialRewards", "[]"], _taskID, "special"] call FUNC(parseRewards);

[
    "hostage",
    _taskID,
    _taskPos,
    format ["Hostage Rescue: %1", _taskID],
    "Locate and rescue the hostages and bring them to the extraction zone.",
    createHashMapFromArray [
        ["hostages", _hostageEntities],
        ["shooters", _shooterEntities]
    ],
    createHashMapFromArray [
        ["limitFail", _logic getVariable ["LimitFail", -1]],
        ["limitSuccess", _logic getVariable ["LimitSuccess", -1]],
        ["funds", _logic getVariable ["CompanyFunds", 0]],
        ["ratingFail", _logic getVariable ["RatingFail", 0]],
        ["ratingSuccess",   _logic getVariable ["RatingSuccess", 0]],
        ["endSuccess", _logic getVariable ["EndSuccess", false]],
        ["endFail", _logic getVariable ["EndFail", false]],
        ["timeLimit", _logic getVariable ["TimeLimit", 0]],
        ["extractionZone", _logic getVariable ["ExtZone", ""]],
        ["cbrn", _logic getVariable ["CBRN", false]],
        ["execution", _logic getVariable ["Execution", false]],
        ["cbrnZone", _logic getVariable ["CBRNZone", ""]],
        ["equipment", _equipmentRewards],
        ["supplies", _supplyRewards],
        ["weapons", _weaponRewards],
        ["vehicles", _vehicleRewards],
        ["special", _specialRewards]
    ]
] call FUNC(startTask);

deleteVehicle _logic;
