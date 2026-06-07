#include "script_component.hpp"

[{
    EGVAR(locker,VARepository) get "isLoaded";
}, {
    ("NotificationHudLayer" call BFUNC(rscLayer)) cutRsc ["RscNotifications", "PLAIN"];
    call FUNC(openUI);
    if (isNil QGVAR(NotificationService)) then { call FUNC(initService); true };
}] call CFUNC(waitUntilAndExecute);

[QGVAR(recieveNotification), {
    params [["_type", "", [""]], ["_title", "", [""]], ["_content", "", [""]], ["_duration", 4000, [4000]]];

    playSound QGVAR(notify);
    GVAR(NotificationService) call ["create", [_type, _title, _content, _duration]];
}] call CFUNC(addEventHandler);
