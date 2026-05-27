#include "script_component.hpp"

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

[QGVAR(requestTransport), {
    params [
        ["_unit", objNull, [objNull]],
        ["_fromNode", objNull, [objNull]],
        ["_toNode", objNull, [objNull]],
        ["_options", createHashMap, [createHashMap]]
    ];

    if (isNull _unit || { isNull _fromNode || { isNull _toNode } }) exitWith {};

    if (isNil QGVAR(TransportService)) then {
        call FUNC(initTransportService);
    };

    GVAR(TransportService) call ["requestTransport", [_unit, _fromNode, _toNode, _options]];
}] call CFUNC(addEventHandler);
