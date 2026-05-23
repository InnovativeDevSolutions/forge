#include "..\script_component.hpp"

/*
 * Object-style IED entity controller.
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(IEDEntityController) = +GVAR(EntityControllerBaseClass);
GVAR(IEDEntityController) merge [createHashMapFromArray [
    ["#type", "IEDEntityController"],
    ["#create", compileFinal {
        params [
            ["_taskID", "", [""]],
            ["_entity", objNull, [objNull]],
            ["_controllerParams", createHashMap, [createHashMap]]
        ];

        _self call ["initializeControllerState", [_taskID, _entity, "ied", _controllerParams]];
        _self set ["countdown", _controllerParams getOrDefault ["countdown", _controllerParams getOrDefault ["iedTimer", 0]]];
        _self set ["waitForAcceptance", _controllerParams getOrDefault ["waitForAcceptance", true]];
        _self call ["registerInstance", []];
    }],
    ["#delete", compileFinal {
        _self call ["unregisterInstance", []];
    }],
    ["waitForAssignment", compileFinal {
        private _taskID = _self getOrDefault ["taskID", ""];
        if (_taskID isEqualTo "" || { !(_self getOrDefault ["waitForAcceptance", true]) }) exitWith { true };

        waitUntil {
            sleep 1;
            GVAR(TaskStore) call ["isTaskAccepted", [_taskID]]
        };

        true
    }],
    ["playCountdownSound", compileFinal {
        params [["_timeRemaining", 0, [0]]];

        private _entity = _self getOrDefault ["entity", objNull];
        if (isNull _entity) exitWith { false };

        if (_timeRemaining > 10) exitWith { _entity say3D "FORGE_timerBeep"; true };
        if (_timeRemaining > 5) exitWith { _entity say3D "FORGE_timerBeepShort"; true };

        _entity say3D "FORGE_timerEnd";
        true
    }],
    ["detonate", compileFinal {
        private _entity = _self getOrDefault ["entity", objNull];
        if (isNull _entity || { !alive _entity }) exitWith { false };

        _entity setDamage 1;
        true
    }],
    ["runLoop", compileFinal {
        private _countdown = _self getOrDefault ["countdown", 0];
        if (_countdown <= 0) exitWith {
            _self call ["markAborted", []];
            _self call ["cleanup", []];
            false
        };

        if !(_self call ["registerTaskEntity", ["ieds"]]) exitWith {
            _self call ["markAborted", []];
            _self call ["cleanup", []];
            false
        };

        _self call ["waitForAssignment", []];
        _self call ["markActive", []];

        while { (_self call ["isEntityUsable", []]) && { _countdown > 0 } } do {
            _self call ["playCountdownSound", [_countdown]];
            _countdown = _countdown - 1;
            _self set ["countdown", _countdown];
            sleep 1;
        };

        if ((_self call ["isEntityUsable", []]) && { _countdown <= 0 }) then {
            _self call ["detonate", []];
        };

        _self call ["markFinished", []];
        _self call ["cleanup", []];
        true
    }]
], true];
