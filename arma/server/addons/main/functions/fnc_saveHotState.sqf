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
 * 1: The player's unit, when it is no longer a player (HandleDisconnect). Only
 *    used with a single UID. <OBJECT> (default: objNull)
 * 2: Wait for the database writes to finish before returning (mission end,
 *    server shutdown). Blocks for at most forge_server_main_flushTimeout ms. <BOOL> (default: false)
 *
 * Return Value:
 * True if the flush routine completed (and, when waiting, every write landed). <BOOL>
 */

params [["_uid", "", [""]], ["_unit", objNull, [objNull]], ["_waitForWrites", false, [false]]];

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
        EGVAR(actor,ActorStore) call ["snapshot", [_flushUid, [objNull, _unit] select (_uid isNotEqualTo "")]];
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

if !(_waitForWrites) exitWith { true };

// The stores queue their database writes in the background; wait for them so
// a shutdown right after this does not drop them.
private _timeout = missionNamespace getVariable [QGVAR(flushTimeout), 10000];
["persistence:flush", [str _timeout]] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
private _flushed = _isSuccess && { _result isEqualTo "OK" };

["INFO", format [
    "Hot state flushed for %1 UID(s); database writes %2.",
    count _uids,
    ["did not all finish: " + str _result, "finished"] select _flushed
]] call EFUNC(common,log);

_flushed
