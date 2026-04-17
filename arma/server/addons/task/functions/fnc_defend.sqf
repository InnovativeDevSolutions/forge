#include "..\script_component.hpp"

/*
 * Compatibility adapter for the object-style defend task implementation.
 */

params [
    ["_taskID", "", [""]],
    ["_defenseZone", "", [""]],
    ["_defendTime", 600, [0]],
    ["_companyFunds", 0, [0]],
    ["_ratingFail", 0, [0]],
    ["_ratingSuccess", 0, [0]],
    ["_endSuccess", false, [false]],
    ["_endFail", false, [false]],
    ["_waveCount", 3, [0]],
    ["_waveCooldown", 300, [0]],
    ["_minBlufor", 1, [0]],
    ["_enemyTemplates", [], [[]]],
    ["_equipmentRewards", [], [[]]],
    ["_supplyRewards", [], [[]]],
    ["_weaponRewards", [], [[]]],
    ["_vehicleRewards", [], [[]]],
    ["_specialRewards", [], [[]]]
];

private _taskParams = createHashMapFromArray [
    ["defenseZone", _defenseZone],
    ["defendTime", _defendTime],
    ["funds", _companyFunds],
    ["ratingFail", _ratingFail],
    ["ratingSuccess", _ratingSuccess],
    ["endSuccess", _endSuccess],
    ["endFail", _endFail],
    ["waveCount", _waveCount],
    ["waveCooldown", _waveCooldown],
    ["minBlufor", _minBlufor],
    ["enemyTemplates", _enemyTemplates],
    ["useTaskStore", true]
];

if (_equipmentRewards isNotEqualTo []) then { _taskParams set ["equipment", _equipmentRewards]; };
if (_supplyRewards isNotEqualTo []) then { _taskParams set ["supplies", _supplyRewards]; };
if (_weaponRewards isNotEqualTo []) then { _taskParams set ["weapons", _weaponRewards]; };
if (_vehicleRewards isNotEqualTo []) then { _taskParams set ["vehicles", _vehicleRewards]; };
if (_specialRewards isNotEqualTo []) then { _taskParams set ["special", _specialRewards]; };

private _task = createHashMapObject [
    GVAR(DefendTaskBaseClass),
    [
        _taskID,
        createHashMap,
        _taskParams
    ]
];

_task call ["runLoop", []];
