#include "..\script_component.hpp"

/*
 * Compatibility adapter for the object-style hostage task implementation.
 */

params [
    ["_taskID", "", [""]],
    ["_limitFail", -1, [0]],
    ["_limitSuccess", -1, [0]],
    ["_extZone", "", [""]],
    ["_companyFunds", 0, [0]],
    ["_ratingFail", 0, [0]],
    ["_ratingSuccess", 0, [0]],
    ["_type", [false, true], [[]]],
    ["_endSuccess", false, [false]],
    ["_endFail", false, [false]],
    ["_timeLimit", 0, [0]],
    ["_cbrnZone", "", [""]],
    ["_equipmentRewards", [], [[]]],
    ["_supplyRewards", [], [[]]],
    ["_weaponRewards", [], [[]]],
    ["_vehicleRewards", [], [[]]],
    ["_specialRewards", [], [[]]]
];

private _taskParams = createHashMapFromArray [
    ["limitFail", _limitFail],
    ["limitSuccess", _limitSuccess],
    ["extractionZone", _extZone],
    ["funds", _companyFunds],
    ["ratingFail", _ratingFail],
    ["ratingSuccess", _ratingSuccess],
    ["type", _type],
    ["cbrn", _type param [0, false, [false]]],
    ["execution", _type param [1, true, [false]]],
    ["endSuccess", _endSuccess],
    ["endFail", _endFail],
    ["timeLimit", _timeLimit],
    ["cbrnZone", _cbrnZone],
    ["useTaskStore", true]
];

if (_equipmentRewards isNotEqualTo []) then { _taskParams set ["equipment", _equipmentRewards]; };
if (_supplyRewards isNotEqualTo []) then { _taskParams set ["supplies", _supplyRewards]; };
if (_weaponRewards isNotEqualTo []) then { _taskParams set ["weapons", _weaponRewards]; };
if (_vehicleRewards isNotEqualTo []) then { _taskParams set ["vehicles", _vehicleRewards]; };
if (_specialRewards isNotEqualTo []) then { _taskParams set ["special", _specialRewards]; };

private _task = createHashMapObject [
    GVAR(HostageTaskBaseClass),
    [
        _taskID,
        createHashMapFromArray [
            ["hostages", GVAR(TaskStore) call ["getTaskEntities", ["hostages", _taskID]]],
            ["shooters", GVAR(TaskStore) call ["getTaskEntities", ["shooters", _taskID]]]
        ],
        _taskParams
    ]
];

_task call ["runLoop", []];
