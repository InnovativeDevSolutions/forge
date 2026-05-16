#include "script_component.hpp"

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

// private _category = [QUOTE(MOD_NAME), LLSTRING(displayName)];

[QGVAR(requestInitBank), {
    params [["_uid", "", [""]]];

    if (_uid isEqualTo "") exitWith { diag_log "[FORGE:Server:Bank] Empty/Invalid UID!" };
    GVAR(BankStore) call ["init", [_uid]];
}] call CFUNC(addEventHandler);

[QGVAR(requestHydrateBank), {
    params [["_uid", "", [""]], ["_mode", "bank", [""]], ["_resetAuthorization", false, [false]]];

    if (_uid isEqualTo "") exitWith { diag_log "[FORGE:Server:Bank] Empty/Invalid UID!" };
    GVAR(BankStore) call ["hydrateSession", [_uid, _mode, _resetAuthorization]];
}] call CFUNC(addEventHandler);

[QGVAR(requestDeposit), {
    params [["_uid", "", [""]], ["_amount", 0, [0]]];

    GVAR(BankStore) call ["deposit", [_uid, _amount]];
}] call CFUNC(addEventHandler);

[QGVAR(requestSubmitPin), {
    params [["_uid", "", [""]], ["_pin", "", [""]]];

    GVAR(BankSessionManager) call ["submitPin", [_uid, _pin]];
}] call CFUNC(addEventHandler);

[QGVAR(requestChangePin), {
    params [["_uid", "", [""]], ["_currentPin", "", [""]], ["_newPin", "", [""]]];

    GVAR(BankStore) call ["changePin", [_uid, _currentPin, _newPin]];
}] call CFUNC(addEventHandler);

[QGVAR(requestTransfer), {
    params [["_uid", "", [""]], ["_target", "", [""]], ["_from", "", [""]], ["_amount", 0, [0]]];

    GVAR(BankStore) call ["transfer", [_uid, _target, _amount, createHashMapFromArray [["sourceField", _from]]]];
}] call CFUNC(addEventHandler);

[QGVAR(requestWithdraw), {
    params [["_uid", "", [""]], ["_amount", 0, [0]]];

    GVAR(BankStore) call ["withdraw", [_uid, _amount]];
}] call CFUNC(addEventHandler);

[QGVAR(requestDepositEarnings), {
    params [["_uid", "", [""]], ["_amount", 0, [0]]];

    GVAR(BankStore) call ["depositEarnings", [_uid, _amount]];
}] call CFUNC(addEventHandler);

[QGVAR(requestRepayCreditLine), {
    params [["_uid", "", [""]], ["_amount", 0, [0]]];

    GVAR(BankStore) call ["repayCreditLine", [_uid, _amount]];
}] call CFUNC(addEventHandler);
