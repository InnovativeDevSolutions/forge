#include "..\script_component.hpp"

/*
 * Object-style hostage entity controller.
 *
 * Example:
 * call compile preprocessFileLineNumbers
 *     "\forge\forge_server\addons\task\objects\EntityControllerBaseClass.sqf";
 * call compile preprocessFileLineNumbers
 *     "\forge\forge_server\addons\task\objects\HostageEntityController.sqf";
 *
 * private _controller = createHashMapObject [
 *     GVAR(HostageEntityController),
 *     [
 *         "task_hostage_review",
 *         hostage1,
 *         createHashMapFromArray [
 *             ["rescueRadius", 2],
 *             ["loopAnimation", "acts_executionvictim_loop"],
 *             ["rescueAnimation", "acts_executionvictim_unbow"]
 *         ]
 *     ]
 * ];
 *
 * [_controller] spawn {
 *     params ["_controller"];
 *     _controller call ["runLoop", []];
 * };
 *
 * Note:
 * `runLoop` uses `sleep`, so it must be entered from scheduled code.
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(HostageEntityController) = createHashMapFromArray [
    ["#base", GVAR(EntityControllerBaseClass)],
    ["#type", "HostageEntityController"],
    ["#create", compileFinal {
        params [
            ["_taskID", "", [""]],
            ["_entity", objNull, [objNull]],
            ["_controllerParams", createHashMap, [createHashMap]]
        ];

        _self call ["initializeControllerState", [_taskID, _entity, "hostage", _controllerParams]];
        _self set ["rescueRadius", _controllerParams getOrDefault ["rescueRadius", 2]];
        _self set ["loopAnimation", _controllerParams getOrDefault ["loopAnimation", "acts_executionvictim_loop"]];
        _self set ["rescueAnimation", _controllerParams getOrDefault ["rescueAnimation", "acts_executionvictim_unbow"]];

        _self call ["registerInstance", []];
    }],
    ["#delete", compileFinal {
        _self call ["unregisterInstance", []];
    }],
    ["applyInitialState", compileFinal {
        private _entity = _self getOrDefault ["entity", objNull];
        if (isNull _entity || { !alive _entity }) exitWith { false };

        _entity setCaptive true;
        _entity enableAIFeature ["MOVE", false];
        _entity playMove (_self getOrDefault ["loopAnimation", "acts_executionvictim_loop"]);
        true
    }],
    ["findNearbyRescuer", compileFinal {
        private _entity = _self getOrDefault ["entity", objNull];
        if (isNull _entity || { !alive _entity }) exitWith { objNull };

        private _radius = _self getOrDefault ["rescueRadius", 2];
        private _nearPlayers = allPlayers inAreaArray [ASLToAGL getPosASL _entity, _radius, _radius, 0, false, 2];
        if (_nearPlayers isEqualTo []) exitWith { objNull };

        _nearPlayers select 0
    }],
    ["transitionToRescued", compileFinal {
        params [["_rescuer", objNull, [objNull]]];

        private _entity = _self getOrDefault ["entity", objNull];
        if (isNull _entity || { isNull _rescuer }) exitWith { false };

        [_entity] joinSilent (group _rescuer);
        _entity setCaptive true;
        _entity enableAIFeature ["MOVE", true];
        _entity playMove (_self getOrDefault ["rescueAnimation", "acts_executionvictim_unbow"]);
        true
    }],
    ["runLoop", compileFinal {
        private _entity = _self getOrDefault ["entity", objNull];
        if (isNull _entity) exitWith {
            _self call ["markAborted", []];
            _self call ["cleanup", []];
            false
        };

        _self call ["markActive", []];

        if !(_self call ["applyInitialState", []]) exitWith {
            _self call ["markAborted", []];
            _self call ["cleanup", []];
            false
        };

        private _rescuer = objNull;
        waitUntil {
            sleep 1;

            if (isNull _entity || { !alive _entity }) exitWith { true };

            _rescuer = _self call ["findNearbyRescuer", []];
            !isNull _rescuer
        };

        if (isNull _entity || { !alive _entity }) exitWith {
            _self call ["markAborted", []];
            _self call ["cleanup", []];
            false
        };

        _self call ["transitionToRescued", [_rescuer]];
        _self call ["markFinished", []];
        _self call ["cleanup", []];
        true
    }]
];
