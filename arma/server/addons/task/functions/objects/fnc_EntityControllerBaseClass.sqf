#include "..\script_component.hpp"

/*
 * Object-style base class for object-based entity controllers.
 *
 * Example:
 * call compile preprocessFileLineNumbers
 *     "\forge\forge_server\addons\task\objects\EntityControllerBaseClass.sqf";
 *
 * private _controller = createHashMapObject [
 *     GVAR(EntityControllerBaseClass),
 *     [
 *         "task_review_001",
 *         hostage1,
 *         "custom",
 *         createHashMapFromArray [
 *             ["radius", 2]
 *         ]
 *     ]
 * ];
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(EntityControllerBaseClass) = createHashMapFromArray [
    ["#type", "EntityControllerBaseClass"],
    ["initializeControllerState", compileFinal {
        params [
            ["_taskID", "", [""]],
            ["_entity", objNull, [objNull]],
            ["_controllerType", "custom", [""]],
            ["_controllerParams", createHashMap, [createHashMap]]
        ];

        _self set ["taskID", _taskID];
        _self set ["entity", _entity];
        _self set ["controllerType", _controllerType];
        _self set ["controllerParams", _controllerParams];
        _self set ["status", "created"];
        _self set ["startedAt", -1];
        _self set ["finishedAt", -1];
        true
    }],
    ["#create", compileFinal {
        private _taskID = "";
        private _entity = objNull;
        private _controllerType = "custom";
        private _controllerParams = createHashMap;

        if (_this isEqualType [] && { count _this > 0 }) then {
            _taskID = _this param [0, "", [""]];
            _entity = _this param [1, objNull, [objNull]];

            if ((count _this > 2) && { (_this select 2) isEqualType "" }) then {
                _controllerType = _this param [2, "custom", [""]];
                _controllerParams = _this param [3, createHashMap, [createHashMap]];
            } else {
                _controllerParams = _this param [2, createHashMap, [createHashMap]];
            };
        };

        _self call ["initializeControllerState", [_taskID, _entity, _controllerType, _controllerParams]];
    }],
    ["getEntity", compileFinal {
        _self getOrDefault ["entity", objNull]
    }],
    ["getRegistryKey", compileFinal {
        private _entity = _self getOrDefault ["entity", objNull];
        if (isNull _entity) exitWith { "" };

        format ["%1_controller_%2", _self getOrDefault ["controllerType", "custom"], netId _entity]
    }],
    ["getTaskID", compileFinal {
        _self getOrDefault ["taskID", ""]
    }],
    ["isEntityUsable", compileFinal {
        private _entity = _self getOrDefault ["entity", objNull];
        !isNull _entity && { alive _entity }
    }],
    ["assignTaskVariable", compileFinal {
        private _entity = _self getOrDefault ["entity", objNull];
        private _taskID = _self getOrDefault ["taskID", ""];
        if (isNull _entity || { _taskID isEqualTo "" }) exitWith { false };

        _entity setVariable ["assignedTask", _taskID, true];
        _entity setVariable [QGVAR(assignedTask), _taskID, true];
        true
    }],
    ["registerTaskEntity", compileFinal {
        params [["_role", "", [""]]];

        private _taskID = _self getOrDefault ["taskID", ""];
        private _entity = _self getOrDefault ["entity", objNull];
        private _useTaskStore = (_self getOrDefault ["controllerParams", createHashMap]) getOrDefault ["useTaskStore", true];

        if (_role isEqualTo "" || { _taskID isEqualTo "" } || { isNull _entity }) exitWith { false };
        _self call ["assignTaskVariable", []];

        if (_useTaskStore) then {
            GVAR(TaskStore) call ["registerTaskEntity", [_role, _taskID, _entity]];
        };

        true
    }],
    ["registerInstance", compileFinal {
        private _registryKey = _self call ["getRegistryKey", []];
        if (_registryKey isEqualTo "") exitWith { false };

        private _registry = missionNamespace getVariable [QGVAR(ObjectControllerInstances), createHashMap];
        _registry set [_registryKey, _self];
        missionNamespace setVariable [QGVAR(ObjectControllerInstances), _registry];
        missionNamespace setVariable [_registryKey, _self];
        true
    }],
    ["unregisterInstance", compileFinal {
        private _registryKey = _self call ["getRegistryKey", []];
        if (_registryKey isEqualTo "") exitWith { false };

        private _registry = missionNamespace getVariable [QGVAR(ObjectControllerInstances), createHashMap];
        _registry deleteAt _registryKey;
        missionNamespace setVariable [_registryKey, nil];
        true
    }],
    ["markActive", compileFinal {
        _self set ["status", "active"];
        _self set ["startedAt", serverTime];
        true
    }],
    ["markFinished", compileFinal {
        _self set ["status", "finished"];
        _self set ["finishedAt", serverTime];
        true
    }],
    ["markAborted", compileFinal {
        _self set ["status", "aborted"];
        _self set ["finishedAt", serverTime];
        true
    }],
    ["cleanup", compileFinal {
        _self call ["unregisterInstance", []]
    }],
    ["runLoop", compileFinal {
        false
    }]
];
