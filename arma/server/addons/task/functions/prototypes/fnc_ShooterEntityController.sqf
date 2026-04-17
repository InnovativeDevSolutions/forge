#include "..\script_component.hpp"

/*
 * Review-only prototype shooter entity controller.
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(ShooterEntityController) = createHashMapFromArray [
    ["#base", GVAR(EntityControllerBaseClass)],
    ["#type", "ShooterEntityController"],
    ["#create", compileFinal {
        params [
            ["_taskID", "", [""]],
            ["_entity", objNull, [objNull]],
            ["_controllerParams", createHashMap, [createHashMap]]
        ];

        _self call ["initializeControllerState", [_taskID, _entity, "shooter", _controllerParams]];
        _self call ["registerInstance", []];
    }],
    ["#delete", compileFinal {
        _self call ["unregisterInstance", []];
    }],
    ["runLoop", compileFinal {
        if !(_self call ["registerTaskEntity", ["shooters"]]) exitWith {
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
