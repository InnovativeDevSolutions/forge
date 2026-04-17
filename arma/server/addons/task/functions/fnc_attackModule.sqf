#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Initializes the attack module
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
 * [logicObject, [unit1, unit2], true] call forge_server_task_fnc_attackModule;
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_units", [], [[]]], ["_activated", true, [true]]];

if !(_activated) exitWith {};

private _taskID = _logic getVariable ["TaskID", ""];
if (_taskID isEqualTo "") exitWith {
    ["ERROR", "Attack module: no task ID configured."] call EFUNC(common,log);
};

private _syncedEntities = synchronizedObjects _logic;
["INFO", format ["Attack Module: TaskID: %1, Synced entities: %2", _taskID, count _syncedEntities]] call EFUNC(common,log);

private _taskPos = if (_syncedEntities isNotEqualTo []) then {
    getPosATL (_syncedEntities select 0)
} else {
    getPosATL _logic
};

[
    "attack",
    _taskID,
    _taskPos,
    format ["Attack: %1", _taskID],
    "Eliminate all hostile forces in the area.",
    createHashMapFromArray [
        ["targets", _syncedEntities]
    ],
    createHashMapFromArray [
        ["limitFail", _logic getVariable ["LimitFail", -1]],
        ["limitSuccess", _logic getVariable ["LimitSuccess", -1]],
        ["funds", _logic getVariable ["CompanyFunds", 0]],
        ["ratingFail", _logic getVariable ["RatingFail", 0]],
        ["ratingSuccess", _logic getVariable ["RatingSuccess", 0]],
        ["endSuccess", _logic getVariable ["EndSuccess", false]],
        ["endFail", _logic getVariable ["EndFail", false]],
        ["timeLimit", _logic getVariable ["TimeLimit", 0]]
    ]
] call FUNC(startTask);

deleteVehicle _logic;
