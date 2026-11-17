#include "script_component.hpp"

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

private _category = [QUOTE(MOD_NAME), LLSTRING(displayName)];
#include "initSettings.inc.sqf"

if (isServer) then { "forge_server" callExtension ["surreal:reconnect", []]; };

GVAR(PlayerBootstrapRegistry) = createHashMap;

["forge_icom_event", {
    params [["_event", "", [""]], ["_data", createHashMap, [createHashMap]]];

    systemChat format ["ICOM Event: %1", _event];
    diag_log format ["[ICOM] Event received: %1 | Data: %2", _event, _data];

    switch (_event) do {
        case "supply_drop": {
            systemChat "Supply drop event received";

            private _coords = _data getOrDefault ["coords", []];
            private _supplies = _data getOrDefault ["supplies", []];

            diag_log format ["[ICOM] Supply drop at %1 with supplies: %2", _coords, _supplies];
        };
        case "spawn_mission": {
            systemChat "Mission spawn event received";

            private _missionType = _data getOrDefault ["mission_type", ""];
            private _location = _data getOrDefault ["location", []];

            diag_log format ["[ICOM] Spawning mission type '%1' at %2", _missionType, _location];
        };
        case "global_alert": {
            systemChat "Global event received";

            private _message = _data getOrDefault ["message", ""];
            private _severity = _data getOrDefault ["severity", ""];

            diag_log format ["[ICOM] Global event '%1' severity: %2", _message, _severity];
        };
        default {
            diag_log format ["[ICOM] Unhandled event: %1", _event];
        };
    };
}] call CFUNC(addEventHandler);

diag_log "[ICOM] Event handler initialized";

// ICOM "transfer_players" sends players to another server. It is handled here,
// on the extension callback, and never forwarded as forge_icom_event: any
// client can raise a CBA server event, so the transfer must not be reachable
// that way.
//   data: { "uids": [...], "group_of": "<leader uid>", "address", "port", "password", "timeout" }
GVAR(handleIcomTransfer) = compileFinal {
    params [["_data", createHashMap, [createHashMap]]];

    private _targets = +(_data getOrDefault ["uids", []]);
    private _groupOf = _data getOrDefault ["group_of", ""];
    if (_groupOf isNotEqualTo "") then {
        private _leader = [_groupOf] call EFUNC(common,getPlayer);
        if (!isNull _leader) then { _targets pushBack (group _leader); };
    };

    private _sent = [
        _targets,
        _data getOrDefault ["address", ""],
        _data getOrDefault ["port", "2302"],
        _data getOrDefault ["password", ""],
        _data getOrDefault ["timeout", 60]
    ] call FUNC(redirectPlayers);

    diag_log format ["[ICOM] Transfer requested: %1 player(s) sent.", _sent];
};

addMissionEventHandler ["ExtensionCallback", {
    params ["_name", "_function", "_data"];

    if (_name isEqualTo "icom") then {
        private _payload = fromJSON _data;
        if (_payload isEqualType [] && { (_payload param [0, ""]) isEqualTo "transfer_players" }) exitWith {
            [_payload param [1, createHashMap]] call GVAR(handleIcomTransfer);
        };

        ["forge_icom_event", _payload] call CFUNC(serverEvent);
    } else {
        (fromJSON _data) call (missionNamespace getVariable [_function, {
            diag_log "[FORGE:Server] Function does not exist!";
        }]);
    };
}];

addMissionEventHandler ["PlayerConnected", {
    params ["_id", "_uid", "_name", "_jip", "_owner", "_idStr"];
}];

// --- Saving player data ---------------------------------------------------
//
// HandleDisconnect passes the unit the player controlled, so the actor
// snapshot (position, loadout, stance) is taken from it. By PlayerDisconnected
// the unit is no longer a player and cannot be found by UID. Returning nothing
// (not true) lets the engine handle the unit as usual.
GVAR(disconnectSaves) = createHashMap;

addMissionEventHandler ["HandleDisconnect", {
    params ["_unit", "_id", "_uid", "_name"];

    if (_uid isEqualTo "") exitWith {};

    GVAR(disconnectSaves) set [_uid, diag_tickTime];
    [_uid, _unit] call FUNC(saveHotState);

    // Returning true would keep the unit alive as AI; let the engine decide.
    false
}];

// Fallback for players who leave without a unit (still in the lobby, unit
// deleted): HandleDisconnect does not fire for them. Waits a moment so a
// HandleDisconnect save of the same player is not repeated.
addMissionEventHandler ["PlayerDisconnected", {
    params ["_id", "_uid", "_name", "_jip", "_owner", "_idStr"];

    if (_uid isEqualTo "") exitWith {};

    [{
        params ["_uid"];
        private _savedAt = GVAR(disconnectSaves) getOrDefault [_uid, -1];
        GVAR(disconnectSaves) deleteAt _uid;
        if (_savedAt >= 0 && { diag_tickTime - _savedAt < 30 }) exitWith {};

        [_uid] call FUNC(saveHotState);
    }, [_uid], 2] call CFUNC(waitAndExecute);
}];

// Periodic autosave, so a crash or a killed server loses at most one interval.
GVAR(lastAutosave) = diag_tickTime;
[{
    private _minutes = missionNamespace getVariable [QGVAR(autosaveInterval), 5];
    if (_minutes <= 0) exitWith {};
    if (diag_tickTime - GVAR(lastAutosave) < _minutes * 60) exitWith {};

    GVAR(lastAutosave) = diag_tickTime;

    // Connected players only: anyone who left was saved on disconnect.
    private _uids = (allPlayers apply { getPlayerUID _x }) select { _x isNotEqualTo "" };
    if (_uids isEqualTo []) exitWith {};

    { [_x] call FUNC(saveHotState); } forEach _uids;
    ["INFO", format ["Autosave: hot state written for %1 player(s).", count _uids]] call EFUNC(common,log);
}, 30] call CFUNC(addPerFrameHandler);

// Mission end and server shutdown: save everyone once and wait for the
// database writes before the process can exit. Ended and MPEnded can both fire.
GVAR(missionEndSaved) = false;
{
    addMissionEventHandler [_x, {
        if (GVAR(missionEndSaved)) exitWith {};
        GVAR(missionEndSaved) = true;

        ["", objNull, true] call FUNC(saveHotState);
    }];
} forEach ["Ended", "MPEnded"];
