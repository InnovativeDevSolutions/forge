#include "..\script_component.hpp"

/*
 * File: fnc_redirectToServer.sqf
 * Author: IDSolutions
 * Date: 2026-11-16
 * Public: No
 *
 * Description:
 * Moves this client to another server: leaves the mission, backs out to the
 * main menu and connects with connectToServer.
 *
 * Only runs when remote executed by the server (remoteExecutedOwner 2), so a
 * client cannot send other players away. Start it from the server with
 * forge_server_main_fnc_redirectPlayers.
 *
 * The target and the step code are kept in uiNamespace, which survives the
 * mission ending. The steps run from onEachFrame
 * (forge_client_common_fnc_redirectStep). Loading the main menu background
 * scene clears onEachFrame; XEH_postInit of that scene starts it again.
 * Note that this replaces any onEachFrame code set by the mission, which is
 * about to end.
 *
 * Arguments:
 * 0: Server address <STRING>
 * 1: Server port <STRING|NUMBER>
 * 2: Server password, "" for none <STRING>
 * 3: Timeout in seconds <NUMBER> (default: 60)
 *
 * Return Value:
 * True when the redirect started <BOOL>
 *
 * Example:
 * Server only:
 * ["203.0.113.10", "2302", "secret", 60] remoteExecCall ["forge_client_common_fnc_redirectToServer", _owner];
 */

if (isServer || { !isRemoteExecuted } || { remoteExecutedOwner isNotEqualTo 2 }) exitWith {
    diag_log "[FORGE:Client:Redirect] Ignored: a redirect must be remote executed by the server.";
    false
};

params [
    ["_address", "", [""]],
    ["_port", "2302", ["", 0]],
    ["_password", "", [""]],
    ["_timeout", 60, [0]]
];

if (_port isEqualType "") then { _port = parseNumber _port; };

if (_address isEqualTo "" || { _port <= 0 } || { _port > 65535 }) exitWith {
    diag_log format ["[FORGE:Client:Redirect] Ignored: invalid server address or port (%1:%2).", _address, _port];
    false
};

// [address, port, password, deadline, last connect attempt]
uiNamespace setVariable [QGVAR(redirectTarget), [_address, _port, _password, diag_tickTime + (_timeout max 15), -1e9]];
uiNamespace setVariable [QGVAR(redirectStep), FUNC(redirectStep)];

diag_log format ["[FORGE:Client:Redirect] Moving to %1:%2.", _address, _port];

onEachFrame { call (uiNamespace getVariable [QGVAR(redirectStep), { onEachFrame {} }]) };

true
