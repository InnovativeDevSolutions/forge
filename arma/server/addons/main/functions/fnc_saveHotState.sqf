#include "..\script_component.hpp"

/*
 * File: fnc_saveHotState.sqf
 * Author: IDSolutions
 * Date: 2026-04-01
 * Public: No
 *
 * Description:
 * Flushes extension-backed hot state for a single UID or every known UID.
 *
 * Arguments:
 * 0: UID to flush. Empty string flushes all known players. <STRING>
 *
 * Return Value:
 * True if the flush routine completed. <BOOL>
 */

params [["_uid", "", [""]]];

private _uids = [];
if (_uid isEqualTo "") then {
    {
        if (isNull _x) then { continue; };
        private _playerUid = getPlayerUID _x;
        if (_playerUid isNotEqualTo "") then {
            _uids pushBackUnique _playerUid;
        };
    } forEach allPlayers;

    if !(isNil QEGVAR(actor,ActorStore)) then {
        {
            if (_x isNotEqualTo "") then {
                _uids pushBackUnique _x;
            };
        } forEach (EGVAR(actor,ActorStore) call ["listHotUids", []]);
    };
} else {
    _uids pushBack _uid;
};

{
    private _flushUid = _x;
    if (_flushUid isEqualTo "") then { continue; };

    private _orgID = "default";
    if !(isNil QEGVAR(org,OrgStore)) then {
        _orgID = EGVAR(org,OrgStore) call ["resolveOrgIdForUid", [_flushUid]];
        if (_orgID isEqualTo "") then {
            _orgID = "default";
        };
    };

    if !(isNil QEGVAR(actor,ActorStore)) then {
        EGVAR(actor,ActorStore) call ["snapshot", [_flushUid]];
        EGVAR(actor,ActorStore) call ["save", [_flushUid]];
    };

    if !(isNil QEGVAR(bank,BankStore)) then {
        EGVAR(bank,BankStore) call ["save", [_flushUid]];
    };

    if !(isNil QEGVAR(locker,LockerStore)) then {
        EGVAR(locker,LockerStore) call ["save", [_flushUid]];
    };

    if !(isNil QEGVAR(locker,VAStore)) then {
        EGVAR(locker,VAStore) call ["save", [_flushUid]];
    };

    if !(isNil QEGVAR(garage,GarageStore)) then {
        EGVAR(garage,GarageStore) call ["save", [_flushUid]];
    };

    if !(isNil QEGVAR(garage,VGarageStore)) then {
        EGVAR(garage,VGarageStore) call ["save", [_flushUid]];
    };

    if !(isNil QEGVAR(org,OrgStore)) then {
        EGVAR(org,OrgStore) call ["saveById", [_orgID]];
    };
} forEach _uids;

true
