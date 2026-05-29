#include "script_component.hpp"

call FUNC(initGarage);

if (isNil QEGVAR(common,EventBus)) then { call EFUNC(common,eventBus); };
if (isNil QGVAR(SyncEventTokens)) then {
    private _sendVGarageSync = {
        params ["_event"];

        private _uid = _event getOrDefault ["uid", ""];
        private _patch = _event getOrDefault ["patch", createHashMap];

        if (_uid isEqualTo "" || { _patch isEqualTo createHashMap }) exitWith {};

        private _player = [_uid] call EFUNC(common,getPlayer);
        if (isNull _player) exitWith {};

        [CRPC(garage,responseSyncVG), [_patch], _player] call CFUNC(targetEvent);
    };

    GVAR(SyncEventTokens) = [
        EGVAR(common,EventBus) call ["on", ["garage.vgarage.sync.requested", _sendVGarageSync, "garage.vgarage.sync"]]
    ];
};
