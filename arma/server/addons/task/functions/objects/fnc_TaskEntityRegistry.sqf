#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Runtime entity registry for task-owned Arma objects.
 *
 * Stores object references by registry key and task ID. TaskStore remains the
 * public facade, while this object owns entity storage and lookup behavior.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Task entity registry object <HASHMAP OBJECT>
 *
 * Public: No
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(TaskEntityRegistry) = createHashMapObject [[
    ["#type", "TaskEntityRegistry"],
    ["#create", compileFinal {
        _self call ["resetRuntimeState", []];
    }],
    ["resetRuntimeState", compileFinal {
        _self set ["taskEntityRegistries", createHashMapFromArray [
            ["cargo", createHashMap],
            ["hostages", createHashMap],
            ["hvts", createHashMap],
            ["ieds", createHashMap],
            ["entities", createHashMap],
            ["shooters", createHashMap],
            ["targets", createHashMap]
        ]];
        true
    }],
    ["registerTaskEntity", compileFinal {
        params [["_registryKey", "", [""]], ["_taskID", "", [""]], ["_entity", objNull, [objNull]]];

        if (_registryKey isEqualTo "" || { _taskID isEqualTo "" } || { isNull _entity }) exitWith { false };

        private _taskEntityRegistries = _self getOrDefault ["taskEntityRegistries", createHashMap];
        private _registry = +(_taskEntityRegistries getOrDefault [_registryKey, createHashMap]);
        private _entities = +(_registry getOrDefault [_taskID, []]);
        _entities pushBackUnique _entity;
        _registry set [_taskID, _entities];
        _taskEntityRegistries set [_registryKey, _registry];
        _self set ["taskEntityRegistries", _taskEntityRegistries];

        true
    }],
    ["getTaskEntities", compileFinal {
        params [["_registryKey", "", [""]], ["_taskID", "", [""]]];

        if (_registryKey isEqualTo "" || { _taskID isEqualTo "" }) exitWith { [] };

        private _taskEntityRegistries = _self getOrDefault ["taskEntityRegistries", createHashMap];
        private _registry = _taskEntityRegistries getOrDefault [_registryKey, createHashMap];

        +(_registry getOrDefault [_taskID, []])
    }],
    ["findTaskEntityOwner", compileFinal {
        params [["_registryKey", "", [""]], ["_entity", objNull, [objNull]]];

        if (_registryKey isEqualTo "" || { isNull _entity }) exitWith { "" };

        private _taskEntityRegistries = _self getOrDefault ["taskEntityRegistries", createHashMap];
        private _registry = _taskEntityRegistries getOrDefault [_registryKey, createHashMap];
        private _resolvedTaskID = "";

        {
            private _taskID = _x;
            private _entities = _y;

            if (_entity in _entities) exitWith { _resolvedTaskID = _taskID; };

            private _matchingEntity = _entities select {
                !isNull _x
                && { (typeOf _x) isEqualTo (typeOf _entity) }
                && { _x distance _entity < 1 }
            };

            if (_matchingEntity isNotEqualTo []) exitWith { _resolvedTaskID = _taskID; };
        } forEach _registry;

        _resolvedTaskID
    }],
    ["clearTaskEntities", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { false };

        private _taskEntityRegistries = _self getOrDefault ["taskEntityRegistries", createHashMap];

        {
            private _registry = +_y;
            _registry deleteAt _taskID;
            _taskEntityRegistries set [_x, _registry];
        } forEach _taskEntityRegistries;

        _self set ["taskEntityRegistries", _taskEntityRegistries];
        true
    }]
]];

GVAR(TaskEntityRegistry)
