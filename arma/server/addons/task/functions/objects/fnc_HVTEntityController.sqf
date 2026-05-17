#include "..\script_component.hpp"

/*
 * Object-style HVT entity controller.
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(HVTEntityController) = createHashMapFromArray [
    ["#base", GVAR(EntityControllerBaseClass)],
    ["#type", "HVTEntityController"],
    ["#create", compileFinal {
        params [
            ["_taskID", "", [""]],
            ["_entity", objNull, [objNull]],
            ["_controllerParams", createHashMap, [createHashMap]]
        ];

        _self call ["initializeControllerState", [_taskID, _entity, "hvt", _controllerParams]];
        _self set ["captureRadius", _controllerParams getOrDefault ["captureRadius", 2]];
        _self call ["registerInstance", []];
    }],
    ["#delete", compileFinal {
        _self call ["unregisterInstance", []];
    }],
    ["findNearbyCapturer", compileFinal {
        private _entity = _self getOrDefault ["entity", objNull];
        if (isNull _entity || { !alive _entity }) exitWith { objNull };

        private _radius = _self getOrDefault ["captureRadius", 2];
        private _nearPlayers = allPlayers inAreaArray [ASLToAGL getPosASL _entity, _radius, _radius, 0, false, 2];
        if (_nearPlayers isEqualTo []) exitWith { objNull };

        _nearPlayers select 0
    }],
    ["transitionToCaptured", compileFinal {
        private _entity = _self getOrDefault ["entity", objNull];
        if (isNull _entity || { !alive _entity }) exitWith { false };

        _entity setCaptive true;
        _entity enableAIFeature ["MOVE", true];
        true
    }],
    ["runLoop", compileFinal {
        if !(_self call ["registerTaskEntity", ["hvts"]]) exitWith {
            _self call ["markAborted", []];
            _self call ["cleanup", []];
            false
        };

        _self call ["markActive", []];

        private _capturer = objNull;
        waitUntil {
            sleep 1;
            if !(_self call ["isEntityUsable", []]) exitWith { true };

            _capturer = _self call ["findNearbyCapturer", []];
            !isNull _capturer
        };

        if !(_self call ["isEntityUsable", []]) exitWith {
            _self call ["markAborted", []];
            _self call ["cleanup", []];
            false
        };

        _self call ["transitionToCaptured", []];
        _self call ["markFinished", []];
        _self call ["cleanup", []];
        true
    }]
];
