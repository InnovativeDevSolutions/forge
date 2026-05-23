#include "..\script_component.hpp"

/*
 * Object-style target entity controller.
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(TargetEntityController) = +GVAR(EntityControllerBaseClass);
GVAR(TargetEntityController) merge [createHashMapFromArray [
    ["#type", "TargetEntityController"],
    ["#create", compileFinal {
        params [
            ["_taskID", "", [""]],
            ["_entity", objNull, [objNull]],
            ["_controllerParams", createHashMap, [createHashMap]]
        ];

        _self call ["initializeControllerState", [_taskID, _entity, "target", _controllerParams]];
        _self call ["registerInstance", []];
    }],
    ["#delete", compileFinal {
        _self call ["unregisterInstance", []];
    }],
    ["runLoop", compileFinal {
        if !(_self call ["registerTaskEntity", ["targets"]]) exitWith {
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
], true];
