#include "script_component.hpp"

if (isNil QGVAR(LockerCompat)) then { call FUNC(initLockerCompat); };

// The locker repository creates its local boxes after the first sync.
[QEGVAR(locker,lockersCreated), {
    params [["_lockers", [], [[]]]];
    GVAR(LockerCompat) call ["adopt", [_lockers]];
}] call CFUNC(addEventHandler);

// Lockers created before this handler was added (late init order).
if (!isNil QEGVAR(locker,LockerRepository)) then {
    private _existing = EGVAR(locker,LockerRepository) getOrDefault ["localLockers", []];
    if (_existing isNotEqualTo []) then { GVAR(LockerCompat) call ["adopt", [_existing]]; };
};

// A server push of new locker contents refills boxes that have no unsaved changes.
[QEGVAR(locker,synced), {
    GVAR(LockerCompat) call ["refresh", []];
}] call CFUNC(addEventHandler);

// AIO raises no event when its window changes a container, so nearby lockers
// are compared against their last saved contents and saved when they differ.
[{
    GVAR(LockerCompat) call ["check", []];
}, LOCKER_CHECK_INTERVAL] call CFUNC(addPerFrameHandler);

diag_log "[FORGE:Client:CompatAIO] Inventory Overhaul compatibility active.";
