#include "script_component.hpp"

call FUNC(initBank);

if (isNil QEGVAR(common,EventBus)) then { call EFUNC(common,eventBus); true };
if (isNil QGVAR(AccountSyncEventTokens)) then {
    private _sendAccountSync = {
        params ["_event"];

        private _uid = _event getOrDefault ["uid", ""];
        private _account = _event getOrDefault ["account", createHashMap];
        private _responseEvent = _event getOrDefault ["responseEvent", CRPC(bank,responseSyncBank)];

        if (_uid isEqualTo "" || { _account isEqualTo createHashMap }) exitWith {};
        GVAR(BankMessenger) call ["sendAccountSync", [_uid, _account, _responseEvent]];
    };

    GVAR(AccountSyncEventTokens) = [
        EGVAR(common,EventBus) call ["on", ["bank.account.sync.requested", _sendAccountSync, "bank.account.sync"]]
    ];
};
