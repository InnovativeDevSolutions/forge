#include "script_component.hpp"

call FUNC(initLocker);

if (isNil QEGVAR(common,EventBus)) then { call EFUNC(common,eventBus); true };
if (isNil QGVAR(SyncEventTokens)) then {
    private _sendLockerSync = {
        params ["_event"];

        private _uid = _event getOrDefault ["uid", ""];
        private _patch = _event getOrDefault ["patch", createHashMap];

        if (_uid isEqualTo "" || { _patch isEqualTo createHashMap }) exitWith {};

        private _player = [_uid] call EFUNC(common,getPlayer);
        if (isNull _player) exitWith {};

        [CRPC(locker,responseSyncLocker), [_patch], _player] call CFUNC(targetEvent);
    };

    private _sendVASync = {
        params ["_event"];

        private _uid = _event getOrDefault ["uid", ""];
        private _patch = _event getOrDefault ["patch", createHashMap];

        if (_uid isEqualTo "" || { _patch isEqualTo createHashMap }) exitWith {};

        private _player = [_uid] call EFUNC(common,getPlayer);
        if (isNull _player) exitWith {};

        [CRPC(locker,responseSyncVA), [_patch], _player] call CFUNC(targetEvent);
    };

    GVAR(SyncEventTokens) = [
        EGVAR(common,EventBus) call ["on", ["locker.sync.requested", _sendLockerSync, "locker.sync"]],
        EGVAR(common,EventBus) call ["on", ["locker.va.sync.requested", _sendVASync, "locker.va.sync"]]
    ];
};
