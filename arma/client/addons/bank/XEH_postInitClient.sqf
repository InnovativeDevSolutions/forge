#include "script_component.hpp"

if (isNil QGVAR(BankRepository)) then { call FUNC(initRepository); };
if (isNil QGVAR(BankUIBridge)) then { call FUNC(initUIBridge); };

[QGVAR(initBank), {
    GVAR(BankRepository) call ["init", []];
}] call CFUNC(addEventHandler);

[QGVAR(responseInitBank), {
    params [["_data", createHashMap, [createHashMap]]];

    GVAR(BankRepository) call ["markLoaded", []];
    if !(isNil QGVAR(BankUIBridge)) then {
        GVAR(BankUIBridge) call ["handleAccountSyncResponse", [_data]];
    };
}] call CFUNC(addEventHandler);

[QGVAR(responseSyncBank), {
    params [["_data", createHashMap, [createHashMap]], ["_jip", false, [false]]];

    GVAR(BankRepository) call ["markLoaded", []];
    if !(isNil QGVAR(BankUIBridge)) then {
        GVAR(BankUIBridge) call ["handleAccountSyncResponse", [_data]];
    };
}] call CFUNC(addEventHandler);

[QGVAR(responseHydrateBank), {
    params [["_data", createHashMap, [createHashMap]]];

    if !(isNil QGVAR(BankUIBridge)) then {
        GVAR(BankUIBridge) call ["handleHydrateResponse", [_data, "bank::hydrate"]];
    };
}] call CFUNC(addEventHandler);

[QGVAR(responseBankNotice), {
    params [["_type", "error", [""]], ["_message", "", [""]]];

    if !(isNil QGVAR(BankUIBridge)) then {
        GVAR(BankUIBridge) call ["handleNoticeResponse", [_type, _message]];
    };
}] call CFUNC(addEventHandler);

[{
    EGVAR(actor,ActorRepository) get "isLoaded";
}, {
    [QGVAR(initBank), []] call CFUNC(localEvent);
}] call CFUNC(waitUntilAndExecute);
