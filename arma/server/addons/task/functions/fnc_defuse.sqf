#include "..\script_component.hpp"

/*
 * Compatibility adapter for the object-style defuse task implementation.
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
    ["useTaskStore", true]
];

if (_equipmentRewards isNotEqualTo []) then { _taskParams set ["equipment", _equipmentRewards]; };
if (_supplyRewards isNotEqualTo []) then { _taskParams set ["supplies", _supplyRewards]; };
if (_weaponRewards isNotEqualTo []) then { _taskParams set ["weapons", _weaponRewards]; };
if (_vehicleRewards isNotEqualTo []) then { _taskParams set ["vehicles", _vehicleRewards]; };
if (_specialRewards isNotEqualTo []) then { _taskParams set ["special", _specialRewards]; };

private _task = createHashMapObject [
    GVAR(DefuseTaskBaseClass),
    [
        _taskID,
        createHashMapFromArray [
            ["ieds", GVAR(TaskStore) call ["getTaskEntities", ["ieds", _taskID]]],
            ["protected", GVAR(TaskStore) call ["getTaskEntities", ["entities", _taskID]]]
        ],
        _taskParams
    ]
];

_task call ["runLoop", []];
