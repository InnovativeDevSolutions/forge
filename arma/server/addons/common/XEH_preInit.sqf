#include "script_component.hpp"

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

// private _category = [QUOTE(MOD_NAME), LLSTRING(displayName)];

if (isNil QGVAR(EventBus)) then { call FUNC(eventBus); true };
if (isNil QGVAR(NotificationEventTokens)) then {
    private _sendNotification = {
        params ["_event"];

        private _uids = +(_event getOrDefault ["uids", []]);
        private _type = _event getOrDefault ["notificationType", "info"];
        private _title = _event getOrDefault ["title", ""];
        private _message = _event getOrDefault ["message", ""];
        private _duration = _event getOrDefault ["duration", -1];

        if (_message isEqualTo "" || { _uids isEqualTo [] }) exitWith {};

        private _params = [_type, _title, _message];
        if (_duration >= 0) then {
            _params pushBack _duration;
        };

        {
            private _player = [_x] call FUNC(getPlayer);
            if (isNull _player) then { continue; };
            [CRPC(notifications,recieveNotification), _params, _player] call CFUNC(targetEvent);
        } forEach _uids;
    };

    GVAR(NotificationEventTokens) = [
        GVAR(EventBus) call ["on", ["notification.requested", _sendNotification, "common.notification.send"]]
    ];
};
