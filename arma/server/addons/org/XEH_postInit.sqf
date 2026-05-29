#include "script_component.hpp"

if (isNil QEGVAR(common,EventBus)) then { call EFUNC(common,eventBus); };
if (isNil QGVAR(SyncEventTokens)) then {
    private _sendOrgSync = {
        params ["_event"];

        private _patch = _event getOrDefault ["patch", createHashMap];
        private _memberUids = +(_event getOrDefault ["memberUids", []]);

        if (_memberUids isEqualTo []) exitWith {};

        {
            private _player = [_x] call EFUNC(common,getPlayer);
            if (isNull _player) then { continue; };
            [CRPC(org,responseSyncOrg), [_patch], _player] call CFUNC(targetEvent);
        } forEach _memberUids;
    };

    GVAR(SyncEventTokens) = [
        EGVAR(common,EventBus) call ["on", ["org.sync.requested", _sendOrgSync, "org.sync"]]
    ];
};
