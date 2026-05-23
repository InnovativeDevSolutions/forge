#include "..\script_component.hpp"

/*
 * File: fnc_initActivityRepository.sqf
 * Author: IDSolutions
 * Date: 2026-03-30
 * Public: No
 *
 * Description:
 * Initializes the CAD activity repository for recent operational events.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * CAD activity repository object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_server_cad_fnc_initActivityRepository
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(ActivityRepositoryBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "CadActivityRepositoryBaseClass"],
    ["appendEntry", compileFinal {
        params [["_entry", createHashMap, [createHashMap]]];

        if (_entry isEqualTo createHashMap) exitWith { false };
        private _finalEntry = +_entry;
        if ((_finalEntry getOrDefault ["timestamp", -1]) < 0) then {
            _finalEntry set ["timestamp", serverTime];
        };

        private _persistenceService = _self getOrDefault ["persistenceService", createHashMap];
        if (_persistenceService isEqualTo createHashMap) exitWith { false };

        _persistenceService call ["appendActivity", [_finalEntry]]
    }],
    ["appendActivity", compileFinal {
        params [
            ["_type", "", [""]],
            ["_message", "", [""]],
            ["_taskID", "", [""]],
            ["_groupID", "", [""]],
            ["_actorUid", "", [""]]
        ];

        if (_type isEqualTo "" || { _message isEqualTo "" }) exitWith { false };
        private _entry = createHashMapFromArray [
            ["type", _type],
            ["message", _message],
            ["taskId", _taskID],
            ["groupId", _groupID],
            ["actorUid", _actorUid]
        ];
        _self call ["appendEntry", [_entry]]
    }],
    ["getActivity", compileFinal {
        private _persistenceService = _self getOrDefault ["persistenceService", createHashMap];
        if (_persistenceService isEqualTo createHashMap) exitWith { [] };

        private _result = _persistenceService call ["loadActivity", []];
        if !(_result getOrDefault ["success", false]) exitWith { [] };

        +(_result getOrDefault ["data", []])
    }]
];

createHashMapObject [GVAR(ActivityRepositoryBaseClass)]
