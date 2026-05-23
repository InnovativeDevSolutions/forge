#include "script_component.hpp"

if (isNil QGVAR(GarageHelperService)) then { call FUNC(initHelperService); };
if (isNil QGVAR(GarageRepository)) then { call FUNC(initRepository); };
if (isNil QGVAR(GarageContextService)) then { call FUNC(initContextService); };
if (isNil QGVAR(GaragePayloadService)) then { call FUNC(initPayloadService); };
if (isNil QGVAR(GarageActionService)) then { call FUNC(initActionService); };
if (isNil QGVAR(GarageUIBridge)) then { call FUNC(initUIBridge); };
if (isNil QGVAR(VGRepository)) then { call FUNC(initVGRepository); };

[QGVAR(initGarage), {
    GVAR(GarageRepository) call ["init", []];
}] call CFUNC(addEventHandler);

[QGVAR(responseInitGarage), {
    params [["_data", createHashMap, [createHashMap]]];

    GVAR(GarageRepository) call ["sync", [_data]];
    if !(isNil QGVAR(GarageUIBridge)) then {
        GVAR(GarageUIBridge) call ["refreshGarage", []];
    };
}] call CFUNC(addEventHandler);

[QGVAR(responseSyncGarage), {
    params [["_data", createHashMap, [createHashMap, []]]];

    GVAR(GarageRepository) call ["sync", [_data]];
    if !(isNil QGVAR(GarageUIBridge)) then {
        GVAR(GarageUIBridge) call ["refreshGarage", []];
    };
}] call CFUNC(addEventHandler);

[QGVAR(responseGarageAction), {
    params [["_payload", createHashMap, [createHashMap]]];

    if !(isNil QGVAR(GarageActionService)) then {
        GVAR(GarageActionService) call ["handleActionResponse", [_payload]];
    };
}] call CFUNC(addEventHandler);

[QGVAR(initVG), {
    GVAR(VGRepository) call ["init", []];
}] call CFUNC(addEventHandler);

[QGVAR(responseInitVG), {
    params [["_data", createHashMap, [createHashMap]]];

    GVAR(VGRepository) call ["sync", [_data]];
}] call CFUNC(addEventHandler);

[QGVAR(responseSyncVG), {
    params [["_data", createHashMap, [createHashMap, []]]];

    GVAR(VGRepository) call ["sync", [_data]];
}] call CFUNC(addEventHandler);

[{
    EGVAR(actor,ActorRepository) get "isLoaded";
}, {
    [QGVAR(initGarage), []] call CFUNC(localEvent);
}] call CFUNC(waitUntilAndExecute);

[{
    GVAR(GarageRepository) get "isLoaded";
}, {
    [QGVAR(initVG), []] call CFUNC(localEvent);
}] call CFUNC(waitUntilAndExecute);
