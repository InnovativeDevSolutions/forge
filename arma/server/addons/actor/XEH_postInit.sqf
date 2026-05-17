#include "script_component.hpp"

if (isNil QEGVAR(common,EventBus)) then { call EFUNC(common,eventBus); };
if (isNil QGVAR(BankAccountCreatedEventTokens)) then {
    private _welcomeNewActor = {
        params ["_event"];

        private _uid = _event getOrDefault ["uid", ""];
        if (_uid isEqualTo "" || { isNil QGVAR(ActorStore) }) exitWith {};

        private _actor = GVAR(ActorStore) call ["get", [_uid, ""]];
        if !(_actor isEqualType createHashMap) then {
            _actor = createHashMap;
        };

        if (_actor isEqualTo createHashMap) then {
            private _player = [_uid] call EFUNC(common,getPlayer);
            _actor = GVAR(ActorModel) call ["fromPlayer", [_player]];
            _actor set ["uid", _uid];
        };

        GVAR(ActorStore) call ["welcomeNewActor", [_uid, _actor]];
    };

    GVAR(BankAccountCreatedEventTokens) = [
        EGVAR(common,EventBus) call ["on", ["bank.account.created", _welcomeNewActor, "actor.newActor.welcome"]]
    ];
};
