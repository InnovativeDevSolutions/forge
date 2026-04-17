#include "..\script_component.hpp"

/*
 * Review-only prototype defense enemy controller.
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(DefenseEnemyController) = createHashMapFromArray [
    ["#base", GVAR(EntityControllerBaseClass)],
    ["#type", "DefenseEnemyController"],
    ["#create", compileFinal {
        params [
            ["_taskID", "", [""]],
            ["_entity", objNull, [objNull]],
            ["_controllerParams", createHashMap, [createHashMap]]
        ];

        _self call ["initializeControllerState", [_taskID, _entity, "defense_enemy", _controllerParams]];
        _self set ["defenseZone", _controllerParams getOrDefault ["defenseZone", ""]];
        _self call ["registerInstance", []];
    }],
    ["#delete", compileFinal {
        _self call ["unregisterInstance", []];
    }],
    ["applyInitialState", compileFinal {
        private _entity = _self getOrDefault ["entity", objNull];
        if (isNull _entity || { !alive _entity }) exitWith { false };

        _self call ["assignTaskVariable", []];
        _entity setBehaviour "AWARE";
        _entity setSpeedMode "NORMAL";
        _entity enableDynamicSimulation true;
        true
    }],
    ["runLoop", compileFinal {
        if !(_self call ["applyInitialState", []]) exitWith {
            _self call ["markAborted", []];
            _self call ["cleanup", []];
            false
        };

        _self call ["markActive", []];
        waitUntil {
            sleep 1;
            !(_self call ["isEntityUsable", []])
        };

        _self call ["markFinished", []];
        _self call ["cleanup", []];
        true
    }]
];
