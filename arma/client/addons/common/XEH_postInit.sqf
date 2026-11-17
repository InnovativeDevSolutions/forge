#include "script_component.hpp"

// Server redirect (forge_client_common_fnc_redirectToServer) in progress.
if (hasInterface) then {
    private _target = uiNamespace getVariable [QGVAR(redirectTarget), []];
    if (_target isEqualTo []) exitWith {};

    // Arrived: the new server's mission is loading.
    if (isMultiplayer) exitWith {
        uiNamespace setVariable [QGVAR(redirectTarget), nil];
        diag_log format ["[FORGE:Client:Redirect] Connected to %1:%2.", _target select 0, _target select 1];
    };

    // Main menu background scene: loading it cleared onEachFrame, so resume.
    onEachFrame { call (uiNamespace getVariable [QGVAR(redirectStep), { onEachFrame {} }]) };
};
