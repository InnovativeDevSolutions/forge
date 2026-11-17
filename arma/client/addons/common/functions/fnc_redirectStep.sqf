#include "..\script_component.hpp"
#include "\a3\ui_f\hpp\defineResincl.inc"

/*
 * File: fnc_redirectStep.sqf
 * Author: IDSolutions
 * Date: 2026-11-17
 * Public: No
 *
 * Description:
 * One frame of a server redirect started by
 * forge_client_common_fnc_redirectToServer. Runs from onEachFrame and is
 * called from uiNamespace, so it must not depend on mission variables or
 * functions (the mission unloads while it runs).
 *
 *   1. Close the mission display and anything on top of it (leaves the server).
 *   2. Close the debriefing, lobby and server browser screens.
 *   3. On the main menu, connect with connectToServer.
 *
 * The connect is retried every 10 seconds until the deadline while the client
 * is not connecting. Arriving on the new server is logged by XEH_postInit.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * onEachFrame { call (uiNamespace getVariable "forge_client_common_redirectStep") };
 */

private _target = uiNamespace getVariable [QGVAR(redirectTarget), []];
if (_target isEqualTo []) exitWith { onEachFrame {}; };

_target params ["_address", "_port", "_password", "_deadline", "_lastTry"];

private _mission = findDisplay IDD_MISSION;
private _connecting = getClientStateNumber > 0;

if (diag_tickTime > _deadline && { !isNull _mission || { !_connecting } }) exitWith {
    uiNamespace setVariable [QGVAR(redirectTarget), nil];
    diag_log format ["[FORGE:Client:Redirect] Timed out: could not connect to %1:%2.", _address, _port];
    onEachFrame {};
};

// 1. Leave the mission.
if (!isNull _mission) exitWith {
    private _displays = allDisplays select [allDisplays find _mission, count allDisplays];
    reverse _displays;
    { _x closeDisplay IDC_CANCEL } forEach _displays;
};

// 2. Back out to the main menu.
{
    private _display = findDisplay _x;
    if (!isNull _display) then { _display closeDisplay IDC_CANCEL };
} forEach [IDD_DEBRIEFING, IDD_CLIENT_GET_READY, IDD_MP_SETUP, IDD_PASSWORD, IDD_IP_ADDRESS, IDD_MULTIPLAYER];

// Still disconnecting from the old server, or already joining the new one.
if (_connecting) exitWith {};

private _main = findDisplay IDD_MAIN;
if (isNull _main || { diag_tickTime - _lastTry < 10 }) exitWith {};

// 3. Connect. connectToServer only works on the main menu and from a UI
// event (a scripted ctrlActivate is not enough), so it runs from the main
// menu's mouse handlers: MouseHolding fires every frame while the mouse is
// still, MouseMoving when it moves. The step only arms the request.
_target set [4, diag_tickTime];
uiNamespace setVariable [QGVAR(redirectConnectArmed), true];
diag_log format ["[FORGE:Client:Redirect] Connecting to %1:%2.", _address, _port];

if !(_main getVariable [QGVAR(redirectHandlers), false]) then {
    _main setVariable [QGVAR(redirectHandlers), true];

    private _connect = {
        if !(uiNamespace getVariable [QGVAR(redirectConnectArmed), false]) exitWith {};
        uiNamespace setVariable [QGVAR(redirectConnectArmed), false];

        (uiNamespace getVariable [QGVAR(redirectTarget), []]) params [["_address", ""], ["_port", 2302], ["_password", ""]];
        if (_address isEqualTo "") exitWith {};

        diag_log format ["[FORGE:Client:Redirect] connectToServer %1:%2 (%3).", _address, _port, _thisEvent];
        connectToServer [_address, _port, _password];
    };

    _main displayAddEventHandler ["MouseHolding", _connect];
    _main displayAddEventHandler ["MouseMoving", _connect];
};
