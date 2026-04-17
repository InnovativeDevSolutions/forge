#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Initializes the hvt module
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
 * [logicObject, [unit1, unit2], true] call forge_server_task_fnc_hvtModule;
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_units", [], [[]]], ["_activated", true, [true]]];

if !(_activated) exitWith {};

private _taskID = _logic getVariable ["TaskID", ""];
if (_taskID isEqualTo "") exitWith {
    ["ERROR", "HVT module: no task ID configured."] call EFUNC(common,log);
};

private _syncedEntities = synchronizedObjects _logic;
["INFO", format [
    "HVT Module: TaskID: %1, ExtZone: %2, CaptureHVT: %3, HVTs: %4",
    _taskID,
    _logic getVariable ["ExtZone", ""],
    _logic getVariable ["CaptureHVT", true],
    count _syncedEntities
]] call EFUNC(common,log);

private _taskPos = if (_syncedEntities isNotEqualTo []) then {
    getPosATL (_syncedEntities select 0)
} else {
    getPosATL _logic
};

private _equipmentRewards = [_logic getVariable ["EquipmentRewards", "[]"], _taskID, "equipment"] call FUNC(parseRewards);
private _supplyRewards = [_logic getVariable ["SupplyRewards", "[]"], _taskID, "supplies"] call FUNC(parseRewards);
private _weaponRewards = [_logic getVariable ["WeaponRewards", "[]"], _taskID, "weapons"] call FUNC(parseRewards);
private _vehicleRewards = [_logic getVariable ["VehicleRewards", "[]"], _taskID, "vehicles"] call FUNC(parseRewards);
private _specialRewards = [_logic getVariable ["SpecialRewards", "[]"], _taskID, "special"] call FUNC(parseRewards);

[
    "hvt",
    _taskID,
    _taskPos,
    format ["HVT: %1", _taskID],
    "Locate and capture or eliminate the high-value target.",
    createHashMapFromArray [
        ["hvts", _syncedEntities]
    ],
    createHashMapFromArray [
        ["limitFail", _logic getVariable ["LimitFail", -1]],
        ["limitSuccess", _logic getVariable ["LimitSuccess", -1]],
        ["funds", _logic getVariable ["CompanyFunds", 0]],
        ["ratingFail", _logic getVariable ["RatingFail", 0]],
        ["ratingSuccess", _logic getVariable ["RatingSuccess", 0]],
        ["endSuccess", _logic getVariable ["EndSuccess", false]],
        ["endFail", _logic getVariable ["EndFail", false]],
        ["timeLimit", _logic getVariable ["TimeLimit", 0]],
        ["extractionZone", _logic getVariable ["ExtZone", ""]],
        ["captureHvt", _logic getVariable ["CaptureHVT", true]],
        ["equipment", _equipmentRewards],
        ["supplies", _supplyRewards],
        ["weapons", _weaponRewards],
        ["vehicles", _vehicleRewards],
        ["special", _specialRewards]
    ]
] call FUNC(startTask);

deleteVehicle _logic;
