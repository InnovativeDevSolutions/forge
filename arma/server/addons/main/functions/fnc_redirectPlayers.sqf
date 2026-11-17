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
 * Number of players sent <NUMBER>
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

{
    private _uid = getPlayerUID _x;

    // Save before they leave; HandleDisconnect saves again when they drop.
    if (_uid isNotEqualTo "") then { [_uid, _x] call FUNC(saveHotState); };

    [_address, _port, _password, _timeout] remoteExecCall ["forge_client_common_fnc_redirectToServer", owner _x];
} forEach _players;

["INFO", format [
    "Redirecting %1 player(s) to %2:%3: %4",
    count _players,
    _address,
    _port,
    _players apply { name _x }
]] call EFUNC(common,log);

count _players
