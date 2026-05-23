#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Registers an attack task.
 *
 * This public function is now a compatibility adapter around
 * AttackTaskBaseClass. Keep the argument list stable for Eden modules,
 * startTask, and external scripts while the object-style task objects
 * become the live implementation.
 *
 * Arguments:
 * 0: ID of the task <STRING>
 * 1: Amount of targets escaped to fail the task <NUMBER>
 * 2: Amount of targets eliminated to complete the task <NUMBER>
 * 3: Amount of funds the company receives if the task is successful <NUMBER>
 * 4: Amount of rating the company and player lose if the task is failed <NUMBER>
 * 5: Amount of rating the company and player receive if the task is successful <NUMBER>
 * 6: Should the mission end if the task is successful <BOOL>
 * 7: Should the mission end if the task is failed <BOOL>
 * 8: Amount of time before target(s) escape <NUMBER>
 * 9: Equipment rewards <ARRAY>
 * 10: Supply rewards <ARRAY>
 * 11: Weapon rewards <ARRAY>
 * 12: Vehicle rewards <ARRAY>
 * 13: Special rewards <ARRAY>
 *
 * Return Value:
 * None
 *
 * Public: Yes
 */

params [
    ["_taskID", "", [""]],
    ["_limitFail", -1, [0]],
    ["_limitSuccess", -1, [0]],
    ["_companyFunds", 0, [0]],
    ["_ratingFail", 0, [0]],
    ["_ratingSuccess", 0, [0]],
    ["_endSuccess", false, [false]],
    ["_endFail", false, [false]],
    ["_timeLimit", 0, [0]],
    ["_equipmentRewards", [], [[]]],
    ["_supplyRewards", [], [[]]],
    ["_weaponRewards", [], [[]]],
    ["_vehicleRewards", [], [[]]],
    ["_specialRewards", [], [[]]]
];

private _taskParams = createHashMapFromArray [
    ["limitFail", _limitFail],
    ["limitSuccess", _limitSuccess],
    ["funds", _companyFunds],
    ["ratingFail", _ratingFail],
    ["ratingSuccess", _ratingSuccess],
    ["endSuccess", _endSuccess],
    ["endFail", _endFail],
    ["timeLimit", _timeLimit],
    ["useTaskStore", true]
];

if (_equipmentRewards isNotEqualTo []) then { _taskParams set ["equipment", _equipmentRewards]; };
if (_supplyRewards isNotEqualTo []) then { _taskParams set ["supplies", _supplyRewards]; };
if (_weaponRewards isNotEqualTo []) then { _taskParams set ["weapons", _weaponRewards]; };
if (_vehicleRewards isNotEqualTo []) then { _taskParams set ["vehicles", _vehicleRewards]; };
if (_specialRewards isNotEqualTo []) then { _taskParams set ["special", _specialRewards]; };

private _task = createHashMapObject [
    GVAR(AttackTaskBaseClass),
    [
        _taskID,
        createHashMapFromArray [["targets", GVAR(TaskStore) call ["getTaskEntities", ["targets", _taskID]]]],
        _taskParams
    ]
];

_task call ["runLoop", []];
