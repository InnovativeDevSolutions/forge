#include "..\script_component.hpp"

/*
 * File: fnc_redirectPlayers.sqf
 * Author: IDSolutions
 * Date: 2026-11-16
 * Public: Yes
 *
 * Description:
 * Sends players to another server. Each player's data is saved first, then
 * their client is told to connect to the new address
 * (forge_client_common_fnc_redirectToServer).
 *
 * The saves are queued in the extension's background persistence tasks, so
 * the redirect waits (in a spawned script, without blocking the server) until
 * `persistence:pending` reports no queued writes, or until
 * forge_server_main_flushTimeout runs out. Otherwise the new server could
 * load the player's data before the last write reached the API. On timeout
 * the players are still sent and a warning is logged.
 *
 * The client only accepts the redirect when it is remote executed by the
 * server, which is why this uses remoteExecCall rather than a CBA event
 * (CBA events do not say who sent them). Missions that restrict remote
 * execution with CfgRemoteExec must allow
 * forge_client_common_fnc_redirectToServer for clients.
 *
 * Arguments:
 * 0: Who to send: a group, a unit, a player UID, or an array of these <GROUP|OBJECT|STRING|ARRAY>
 * 1: Server address <STRING>
 * 2: Server port <STRING> (default: "2302")
 * 3: Server password, "" for none <STRING> (default: "")
 * 4: Timeout in seconds on the client <NUMBER> (default: 60)
 *
 * Return Value:
 * Number of players being sent (the redirect itself happens once their
 * saves have landed) <NUMBER>
 *
 * Example:
 * [group _leader, "203.0.113.10", "2302", "secret"] call forge_server_main_fnc_redirectPlayers;
 * [["76561198000000001", "76561198000000002"], "203.0.113.10"] call forge_server_main_fnc_redirectPlayers;
 */

if (!isServer) exitWith {
    ["WARNING", "redirectPlayers must run on the server."] call EFUNC(common,log);
    0
};

params [
    ["_targets", [], [[], grpNull, objNull, ""]],
    ["_address", "", [""]],
    ["_port", "2302", ["", 0]],
    ["_password", "", [""]],
    ["_timeout", 60, [0]]
];

if (_port isEqualType 0) then { _port = str _port; };

if (_address isEqualTo "" || { _port isEqualTo "" }) exitWith {
    ["WARNING", "redirectPlayers: a server address and port are required."] call EFUNC(common,log);
    0
};

if !(_targets isEqualType []) then { _targets = [_targets]; };

// Resolve every target to player units, once each.
private _players = [];
{
    switch (true) do {
        case (_x isEqualType grpNull): { _players append (units _x); };
        case (_x isEqualType objNull): { _players pushBack _x; };
        case (_x isEqualType ""): { _players pushBack ([_x] call EFUNC(common,getPlayer)); };
    };
} forEach _targets;
_players = (_players arrayIntersect _players) select { !isNull _x && { isPlayer _x } };

if (_players isEqualTo []) exitWith {
    ["WARNING", format ["redirectPlayers: no connected players among %1.", _targets]] call EFUNC(common,log);
    0
};

// Save before they leave; HandleDisconnect saves again when they drop.
{
    private _uid = getPlayerUID _x;
    if (_uid isNotEqualTo "") then { [_uid, _x] call FUNC(saveHotState); };
} forEach _players;

["INFO", format [
    "Redirecting %1 player(s) to %2:%3 once their saves land: %4",
    count _players,
    _address,
    _port,
    _players apply { name _x }
]] call EFUNC(common,log);

// The saves above only queue background writes. Wait for them to reach the
// API before sending anyone, so the new server never loads stale data. The
// pending counter covers every queued write on this server, not only these
// players', so it can wait a little longer than strictly needed.
[_players, _address, _port, _password, _timeout] spawn {
    params ["_players", "_address", "_port", "_password", "_timeout"];

    private _waitMs = missionNamespace getVariable [QGVAR(flushTimeout), 10000];
    private _deadline = diag_tickTime + (_waitMs / 1000);
    private _pending = "?";

    waitUntil {
        sleep 0.1;
        // Called directly rather than through extCall, which logs every call.
        ("forge_server" callExtension ["persistence:pending", []]) params [["_result", ""], ["_extCode", -1], ["_armaCode", -1]];
        _pending = _result;
        (_extCode == 0 && { _result isEqualTo "0" }) || { diag_tickTime >= _deadline }
    };

    if (_pending isNotEqualTo "0") then {
        ["WARNING", format [
            "redirectPlayers: saves did not all land within %1 ms (pending: %2); sending players anyway, the new server may load stale data.",
            _waitMs,
            _pending
        ]] call EFUNC(common,log);
    };

    {
        // A player may have left while the saves were landing.
        if (!isNull _x && { isPlayer _x }) then {
            [_address, _port, _password, _timeout] remoteExecCall ["forge_client_common_fnc_redirectToServer", owner _x];
        };
    } forEach _players;
};

count _players
