#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Initializes the defend task module.
 * Reads parameters from the logic object and delegates to fnc_startTask.
 * The designer must place a named marker in Eden for the defense zone.
 * Synced enemy units are used as wave composition templates.
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
private _defenseZone = _logic getVariable ["DefenseZone", ""];

if (_taskID isEqualTo "") exitWith {
    ["ERROR", "Defend module: no task ID configured."] call EFUNC(common,log);
};
if (_defenseZone isEqualTo "" || { markerShape _defenseZone isEqualTo "" }) exitWith {
    ["ERROR", format ["Defend module '%1': DefenseZone marker '%2' is missing or invalid.", _taskID, _defenseZone]] call EFUNC(common,log);
};

private _syncedEnemies = synchronizedObjects _logic select { _x isKindOf "CAManBase" };
private _templateGroups = [];
private _templateUnits = [];
private _seenGroups = [];

{
    private _group = group _x;
    if (_group in _seenGroups) then { continue; };
    _seenGroups pushBack _group;

    private _templates = [];
    {
        if (isNull _x) then { continue; };
        _templateUnits pushBackUnique _x;
        _templates pushBack createHashMapFromArray [
            ["type", typeOf _x],
            ["loadout", getUnitLoadout _x],
            ["skill", skill _x],
            ["rank", rank _x],
            ["side", side _x]
        ];
    } forEach (units _group);

    if (_templates isNotEqualTo []) then {
        _templateGroups pushBack _templates;
    };
} forEach _syncedEnemies;

{ deleteVehicle _x } forEach _templateUnits;

if (_templateGroups isEqualTo []) then {
    ["WARNING", format [
        "Defend module '%1' has no synced enemy units. Falling back to default CSAT wave templates.",
        _taskID
    ]] call EFUNC(common,log);
};

["INFO", format [
    "Defend Module Parameters: TaskID: %1, DefenseZone: %2, DefendTime: %3, WaveCount: %4, WaveCooldown: %5, MinBlufor: %6, EnemyTemplateGroups: %7",
    _taskID, _defenseZone,
    _logic getVariable ["DefendTime", 600],
    _logic getVariable ["WaveCount", 3],
    _logic getVariable ["WaveCooldown", 300],
    _logic getVariable ["MinBlufor", 1],
    count _templateGroups
]] call EFUNC(common,log);

private _equipmentRewards = [_logic getVariable ["EquipmentRewards", "[]"], _taskID, "equipment"] call FUNC(parseRewards);
private _supplyRewards = [_logic getVariable ["SupplyRewards", "[]"], _taskID, "supplies"] call FUNC(parseRewards);
private _weaponRewards = [_logic getVariable ["WeaponRewards", "[]"], _taskID, "weapons"] call FUNC(parseRewards);
private _vehicleRewards = [_logic getVariable ["VehicleRewards", "[]"], _taskID, "vehicles"] call FUNC(parseRewards);
private _specialRewards = [_logic getVariable ["SpecialRewards", "[]"], _taskID, "special"] call FUNC(parseRewards);
private _taskChainParams = [_logic] call FUNC(parseTaskChainAttributes);

[
    "defend",
    _taskID,
    getMarkerPos _defenseZone,
    format ["Defend: %1", _taskID],
    "Hold the defense zone against incoming enemy forces.",
    createHashMap,
    createHashMapFromArray ([
        ["funds", _logic getVariable ["CompanyFunds", 0]],
        ["ratingFail", _logic getVariable ["RatingFail", 0]],
        ["ratingSuccess", _logic getVariable ["RatingSuccess", 0]],
        ["endSuccess", _logic getVariable ["EndSuccess", false]],
        ["endFail", _logic getVariable ["EndFail", false]],
        ["defenseZone", _defenseZone],
        ["defendTime", _logic getVariable ["DefendTime", 600]],
        ["waveCount", _logic getVariable ["WaveCount", 3]],
        ["waveCooldown", _logic getVariable ["WaveCooldown", 300]],
        ["minBlufor", _logic getVariable ["MinBlufor", 1]],
        ["enemyTemplates", _templateGroups],
        ["equipment", _equipmentRewards],
        ["supplies", _supplyRewards],
        ["weapons", _weaponRewards],
        ["vehicles", _vehicleRewards],
        ["special", _specialRewards]
    ] + _taskChainParams)
] call FUNC(startTask);

deleteVehicle _logic;
