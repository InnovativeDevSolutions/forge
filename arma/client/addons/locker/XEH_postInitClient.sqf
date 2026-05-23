#include "script_component.hpp"

if (isNil QGVAR(LockerRepository)) then { call FUNC(initRepository); };
if (isNil QGVAR(VARepository)) then { call FUNC(initVARepository); };

[QGVAR(initLocker), {
    GVAR(LockerRepository) call ["init", []];
}] call CFUNC(addEventHandler);

[QGVAR(responseInitLocker), {
    params [["_data", createHashMap, [createHashMap]]];

    GVAR(LockerRepository) call ["sync", [_data]];
}] call CFUNC(addEventHandler);

[QGVAR(responseSyncLocker), {
    params [["_data", createHashMap, [createHashMap, []]], ["_jip", false, [false]]];

    GVAR(LockerRepository) call ["sync", [_data, _jip]];
}] call CFUNC(addEventHandler);

[QGVAR(initVA), {
    GVAR(VARepository) call ["init", []];
}] call CFUNC(addEventHandler);

[QGVAR(responseInitVA), {
    params [["_data", createHashMap, [createHashMap]]];

    GVAR(VARepository) call ["sync", [_data]];
}] call CFUNC(addEventHandler);

[QGVAR(responseSyncVA), {
    params [["_data", createHashMap, [createHashMap, []]], ["_jip", false, [false]]];

    GVAR(VARepository) call ["sync", [_data, _jip]];
}] call CFUNC(addEventHandler);

[{
    EGVAR(actor,ActorRepository) get "isLoaded";
}, {
    [QGVAR(initLocker), []] call CFUNC(localEvent);
}] call CFUNC(waitUntilAndExecute);

[{
    GVAR(LockerRepository) get "isLoaded";
}, {
    [QGVAR(initVA), []] call CFUNC(localEvent);
}] call CFUNC(waitUntilAndExecute);
