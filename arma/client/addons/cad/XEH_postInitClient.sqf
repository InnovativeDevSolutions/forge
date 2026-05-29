#include "script_component.hpp"

if (isNil QGVAR(CADRepository)) then { call FUNC(initRepository); };
if (isNil QGVAR(CADUIBridge)) then { call FUNC(initUIBridge); };

[QGVAR(openCAD), {
    call FUNC(openUI);
}] call CFUNC(addEventHandler);

[QGVAR(responseHydrateCad), {
    params [["_payload", createHashMap, [createHashMap]]];

    GVAR(CADUIBridge) call ["handleHydrateResponse", [_payload]];
}] call CFUNC(addEventHandler);

[QGVAR(responseCadAssignment), {
    params [["_result", createHashMap, [createHashMap]]];

    GVAR(CADUIBridge) call ["handleAssignmentResponse", [_result]];
}] call CFUNC(addEventHandler);

[QGVAR(responseCadGroupUpdate), {
    params [["_result", createHashMap, [createHashMap]]];

    GVAR(CADUIBridge) call ["handleGroupUpdateResponse", [_result]];
}] call CFUNC(addEventHandler);

[QGVAR(responseCadRequest), {
    params [["_result", createHashMap, [createHashMap]]];

    GVAR(CADUIBridge) call ["handleRequestResponse", [_result]];
}] call CFUNC(addEventHandler);

[QGVAR(invalidateCadState), {
    if (isNil QGVAR(CADRepository)) exitWith {};
    if !(GVAR(CADRepository) getOrDefault ["isOpen", false]) exitWith {};
    if (isNil QGVAR(CADUIBridge)) exitWith {};

    GVAR(CADUIBridge) call ["requestHydrate", []];
}] call CFUNC(addEventHandler);
