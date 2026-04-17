#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Initializes the delivery task module.
 * Reads parameters from the logic object, collects cargo from the synced
 * FORGE_Module_Cargo grouping module, and delegates to fnc_startTask.
 *
 * Eden layout:
 *   [FORGE_Module_Delivery] --sync--> [FORGE_Module_Cargo] --sync--> cargo_obj1, cargo_obj2
 *
 * Arguments:
 * 0: Logic <OBJECT>
 * 1: Units <ARRAY>
 * 2: Activated <BOOL>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_units", [], [[]]], ["_activated", true, [true]]];

if !(_activated) exitWith {};

private _taskID = _logic getVariable ["TaskID", ""];
if (_taskID isEqualTo "") exitWith {
    ["ERROR", "Delivery module: no task ID configured."] call EFUNC(common,log);
};

private _syncedModules = synchronizedObjects _logic;
private _cargoModule = (_syncedModules select { typeOf _x isEqualTo "FORGE_Module_Cargo" }) param [0, objNull];
private _cargoEntities = if (!isNull _cargoModule) then { synchronizedObjects _cargoModule } else { [] };

["INFO", format [
    "Delivery Module Parameters: TaskID: %1, DeliveryZone: %2, Cargo count: %3",
    _taskID,
    _logic getVariable ["DeliveryZone", ""],
    count _cargoEntities
]] call EFUNC(common,log);

private _taskPos = if (_cargoEntities isNotEqualTo []) then {
    getPosATL (_cargoEntities select 0)
} else {
    getPosATL _logic
};

[
    "delivery",
    _taskID,
    _taskPos,
    format ["Delivery: %1", _taskID],
    "Transport all cargo to the designated delivery zone.",
    createHashMapFromArray [
        ["cargo", _cargoEntities]
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
        ["deliveryZone", _logic getVariable ["DeliveryZone", ""]]
    ]
] call FUNC(startTask);

deleteVehicle _logic;
