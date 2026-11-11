#include "..\script_component.hpp"

/*
 * File: fnc_registerEventListeners.sqf
 * Author: IDSolutions
 * Date: 2026-05-14
 * Public: No
 *
 * Description:
 * Registers CAD listeners for task lifecycle events so open CAD views refresh
 * when contracts are created, started, finished or cleared outside of CAD.
 * CAD's own mutations refresh clients directly from the RPC handler.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Listener tokens [ARRAY]
 *
 * Example:
 * call forge_server_cad_fnc_registerEventListeners
 */

if (isNil QEGVAR(common,EventBus)) then { call EFUNC(common,eventBus); };
if !(isNil QGVAR(TaskEventListenerTokens)) exitWith { GVAR(TaskEventListenerTokens) };

private _invalidateCadState = {
    params ["_event"];

    ["INFO", format [
        "CAD task event received: %1 taskID=%2 status=%3",
        _event getOrDefault ["event", ""],
        _event getOrDefault ["taskID", ""],
        _event getOrDefault ["status", ""]
    ]] call EFUNC(common,log);

    [CRPC(cad,invalidateCadState), []] call CFUNC(globalEvent);
};

GVAR(TaskEventListenerTokens) = ["task.created", "task.started", "task.completed", "task.failed", "task.cleared"] apply {
    EGVAR(common,EventBus) call ["on", [_x, _invalidateCadState, "cad.task.invalidate"]]
};

GVAR(TaskEventListenerTokens)
