#include "script_component.hpp"

if (isNil QGVAR(BankRepository)) then { call FUNC(initRepository); true };
if (isNil QGVAR(BankUIBridge)) then { call FUNC(initUIBridge); true };

GVAR(sendPhoneBankEvent) = {
    params [["_functionName", "", [""]], ["_arguments", [], [[]]]];

    private _display = uiNamespace getVariable ["RscPhone", displayNull];
    if (isNull _display || { _functionName isEqualTo "" }) exitWith { false };

    private _control = _display displayCtrl 1001;
    if (isNull _control) exitWith { false };

    private _serializedArguments = _arguments apply { toJSON _x };
    private _script = format [
        "window.%1 && window.%1(%2)",
        _functionName,
        _serializedArguments joinString ", "
    ];

    _control ctrlWebBrowserAction ["ExecJS", _script];
    true
};

[QGVAR(initBank), {
    GVAR(BankRepository) call ["init", []];
}] call CFUNC(addEventHandler);

[QGVAR(responseInitBank), {
    params [["_data", createHashMap, [createHashMap]]];

    GVAR(BankRepository) call ["markLoaded", []];
    if !(isNil QGVAR(BankUIBridge)) then {
        GVAR(BankUIBridge) call ["handleAccountSyncResponse", [_data]];
    };
    ["updateMobileBankAccount", [_data]] call GVAR(sendPhoneBankEvent);
}] call CFUNC(addEventHandler);

[QGVAR(responseSyncBank), {
    params [["_data", createHashMap, [createHashMap]], ["_jip", false, [false]]];

    GVAR(BankRepository) call ["markLoaded", []];
    if !(isNil QGVAR(BankUIBridge)) then {
        GVAR(BankUIBridge) call ["handleAccountSyncResponse", [_data]];
    };
    ["updateMobileBankAccount", [_data]] call GVAR(sendPhoneBankEvent);
}] call CFUNC(addEventHandler);

[QGVAR(responseHydrateBank), {
    params [["_data", createHashMap, [createHashMap]]];

    if !(isNil QGVAR(BankUIBridge)) then {
        GVAR(BankUIBridge) call ["handleHydrateResponse", [_data, "bank::hydrate"]];
    };
    ["updateMobileBank", [_data]] call GVAR(sendPhoneBankEvent);
}] call CFUNC(addEventHandler);

[QGVAR(responseBankNotice), {
    params [["_type", "error", [""]], ["_message", "", [""]]];

    if !(isNil QGVAR(BankUIBridge)) then {
        GVAR(BankUIBridge) call ["handleNoticeResponse", [_type, _message]];
    };
    ["showMobileBankNotice", [_type, _message]] call GVAR(sendPhoneBankEvent);
}] call CFUNC(addEventHandler);

[{
    EGVAR(actor,ActorRepository) get "isLoaded";
}, {
    [QGVAR(initBank), []] call CFUNC(localEvent);
}] call CFUNC(waitUntilAndExecute);
