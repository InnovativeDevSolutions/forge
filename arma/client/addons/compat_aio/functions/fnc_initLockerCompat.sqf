#include "..\script_component.hpp"

/*
 * File: fnc_initLockerCompat.sqf
 * Author: IDSolutions
 * Date: 2026-11-16
 * Public: No
 *
 * Description:
 * Makes Forge lockers work with AIO - Arma Inventory Overhaul.
 *
 * Forge lockers are boxes made with createVehicleLocal that fill on the
 * vanilla ContainerOpened event and save on ContainerClosed. AIO replaces the
 * vanilla inventory, so those events no longer drive the locker, and AIO
 * sends moves on objects the server cannot see through the server. This
 * object takes over the fill/save cycle for each locker box:
 *
 * - marks the box aio_storage_localOnly (moves run on this machine) and
 *   aio_noSearch (a locker is not loot);
 * - marks it forge_client_locker_externallyManaged so the vanilla container
 *   events leave it alone;
 * - fills it once when it is created;
 * - saves it whenever its contents change (checked every few seconds while
 *   the player is near);
 * - refills it after a server sync when it has no unsaved changes.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Locker compat object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_client_compat_aio_fnc_initLockerCompat
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(LockerCompatBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "LockerCompatAIOBaseClass"],
    ["signature", compileFinal {
        // Order-independent text form of a locker hashmap: "class:amount|...".
        params [["_contents", createHashMap, [createHashMap]]];

        private _classes = keys _contents;
        _classes sort true;
        (_classes apply { format ["%1:%2", _x, (_contents get _x) getOrDefault ["amount", 0]] }) joinString "|"
    }],
    ["remember", compileFinal {
        // Records what the box holds now and which repository state it reflects.
        params [["_locker", objNull, [objNull]]];

        private _repository = EGVAR(locker,LockerRepository);
        _locker setVariable [QGVAR(boxSignature), _self call ["signature", [_repository call ["readContainer", [_locker]]]]];
        _locker setVariable [QGVAR(repoSignature), _self call ["signature", [_repository get "locker"]]];
    }],
    ["isWindowOpen", compileFinal {
        !isNull (uiNamespace getVariable [AIO_DISPLAY, displayNull])
    }],
    ["adopt", compileFinal {
        params [["_lockers", [], [[]]]];

        private _repository = EGVAR(locker,LockerRepository);
        {
            if (isNull _x || { _x getVariable [QGVAR(adopted), false] }) then { continue; };

            _x setVariable [AIO_LOCAL_ONLY, true];
            _x setVariable [AIO_NO_SEARCH, true];
            _x setVariable [QEGVAR(locker,externallyManaged), true];
            _x setVariable [QGVAR(adopted), true];

            _repository call ["fillContainer", [_x]];
            _self call ["remember", [_x]];
        } forEach _lockers;

        diag_log format ["[FORGE:Client:CompatAIO] Adopted %1 locker(s).", count _lockers];
    }],
    ["check", compileFinal {
        // Saves any nearby locker whose contents changed since the last save.
        if (isNil QEGVAR(locker,LockerRepository)) exitWith {};

        private _repository = EGVAR(locker,LockerRepository);
        private _player = call CFUNC(currentUnit);
        if (isNull _player || { !alive _player }) exitWith {};

        {
            if (isNull _x || { !(_x getVariable [QGVAR(adopted), false]) }) then { continue; };
            if ((_player distance _x) > LOCKER_CHECK_RANGE) then { continue; };

            private _current = _self call ["signature", [_repository call ["readContainer", [_x]]]];
            if (_current isEqualTo (_x getVariable [QGVAR(boxSignature), ""])) then { continue; };

            _repository call ["commitContainer", [_x, _player]];
            _self call ["remember", [_x]];
            diag_log "[FORGE:Client:CompatAIO] Locker changed; saved.";
        } forEach (_repository getOrDefault ["localLockers", []]);
    }],
    ["refresh", compileFinal {
        // After a server sync: refill boxes that hold no unsaved changes and
        // whose saved contents moved on. Never while the AIO window is open.
        if (isNil QEGVAR(locker,LockerRepository)) exitWith {};
        if (_self call ["isWindowOpen", []]) exitWith {};

        private _repository = EGVAR(locker,LockerRepository);
        private _repoSignature = _self call ["signature", [_repository get "locker"]];

        {
            if (isNull _x || { !(_x getVariable [QGVAR(adopted), false]) }) then { continue; };
            if (_repoSignature isEqualTo (_x getVariable [QGVAR(repoSignature), ""])) then { continue; };

            private _current = _self call ["signature", [_repository call ["readContainer", [_x]]]];
            if (_current isNotEqualTo (_x getVariable [QGVAR(boxSignature), ""])) then { continue; };

            _repository call ["fillContainer", [_x]];
            _self call ["remember", [_x]];
        } forEach (_repository getOrDefault ["localLockers", []]);
    }]
];

GVAR(LockerCompat) = createHashMapObject [GVAR(LockerCompatBaseClass)];
GVAR(LockerCompat)
