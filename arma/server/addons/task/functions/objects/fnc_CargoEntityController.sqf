#include "..\script_component.hpp"

/*
 * Object-style delivery cargo entity controller.
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(CargoEntityController) = createHashMapFromArray [
    ["#base", GVAR(EntityControllerBaseClass)],
    ["#type", "CargoEntityController"],
    ["#create", compileFinal {
        params [
            ["_taskID", "", [""]],
            ["_entity", objNull, [objNull]],
            ["_controllerParams", createHashMap, [createHashMap]]
        ];

        _self call ["initializeControllerState", [_taskID, _entity, "cargo", _controllerParams]];
        _self set ["damageThreshold", _controllerParams getOrDefault ["damageThreshold", 0.7]];
        _self set ["damageEventId", -1];
        _self call ["registerInstance", []];
    }],
    ["#delete", compileFinal {
        _self call ["cleanup", []];
    }],
    ["watchDamage", compileFinal {
        private _entity = _self getOrDefault ["entity", objNull];
        if (isNull _entity) exitWith { false };

        private _threshold = _self getOrDefault ["damageThreshold", 0.7];
        _entity setVariable [QGVAR(cargoDamageThreshold), _threshold];

        private _eventId = _entity addEventHandler ["Dammaged", {
            params ["_unit"];

            private _threshold = _unit getVariable [QGVAR(cargoDamageThreshold), 0.7];
            if (damage _unit < _threshold) exitWith {};

            private _taskID = _unit getVariable ["assignedTask", _unit getVariable [QGVAR(assignedTask), ""]];
            if (_taskID isEqualTo "") exitWith {};
            if (_unit getVariable [QGVAR(cargoDamageWarned), false]) exitWith {};

            _unit setVariable [QGVAR(cargoDamageWarned), true];
            GVAR(TaskStore) call ["notifyParticipants", [_taskID, "warning", "Tasks", format ["Cargo for task %1 has been severely damaged.", _taskID]]];
        }];

        _self set ["damageEventId", _eventId];
        true
    }],
    ["cleanup", compileFinal {
        private _entity = _self getOrDefault ["entity", objNull];
        private _eventId = _self getOrDefault ["damageEventId", -1];

        if (!isNull _entity && { _eventId >= 0 }) then {
            _entity removeEventHandler ["Dammaged", _eventId];
        };

        _self call ["unregisterInstance", []]
    }],
    ["runLoop", compileFinal {
        if !(_self call ["registerTaskEntity", ["cargo"]]) exitWith {
            _self call ["markAborted", []];
            _self call ["cleanup", []];
            false
        };

        _self call ["watchDamage", []];
        _self call ["markActive", []];

        waitUntil {
            sleep 1;
            private _entity = _self getOrDefault ["entity", objNull];
            isNull _entity || { !alive _entity } || { damage _entity >= (_self getOrDefault ["damageThreshold", 0.7]) }
        };

        _self call ["markFinished", []];
        _self call ["cleanup", []];
        true
    }]
];
