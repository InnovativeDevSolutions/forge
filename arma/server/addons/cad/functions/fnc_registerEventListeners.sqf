#include "..\script_component.hpp"

/*
 * File: fnc_registerEventListeners.sqf
 * Author: IDSolutions
 * Date: 2026-05-14
 * Public: No
 *
 * Description:
 * Registers CAD listeners for framework events that should refresh CAD state.
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
        "CAD task event received: %1 taskID=%2 taskType=%3 status=%4",
        _event getOrDefault ["event", ""],
        _event getOrDefault ["taskID", ""],
        _event getOrDefault ["taskType", ""],
        _event getOrDefault ["status", ""]
    ]] call EFUNC(common,log);

    [CRPC(cad,invalidateCadState), []] call CFUNC(globalEvent);
};

private _invalidateCadAssignmentState = {
    params ["_event"];

    private _assignment = _event getOrDefault ["assignment", createHashMap];
    ["INFO", format [
        "CAD assignment event received: %1 taskID=%2 groupID=%3 state=%4",
        _event getOrDefault ["event", ""],
        _event getOrDefault ["taskID", ""],
        _assignment getOrDefault ["groupId", ""],
        _assignment getOrDefault ["state", ""]
    ]] call EFUNC(common,log);

    [CRPC(cad,invalidateCadState), []] call CFUNC(globalEvent);
};

private _invalidateCadRequestState = {
    params ["_event"];

    ["INFO", format [
        "CAD request event received: %1 requestID=%2 groupID=%3",
        _event getOrDefault ["event", ""],
        _event getOrDefault ["requestID", ""],
        _event getOrDefault ["groupID", ""]
    ]] call EFUNC(common,log);

    [CRPC(cad,invalidateCadState), []] call CFUNC(globalEvent);
};

private _invalidateCadGroupState = {
    params ["_event"];

    private _group = _event getOrDefault ["group", createHashMap];
    ["INFO", format [
        "CAD group event received: %1 groupID=%2 status=%3 role=%4",
        _event getOrDefault ["event", ""],
        _event getOrDefault ["groupID", ""],
        _group getOrDefault ["status", ""],
        _group getOrDefault ["role", ""]
    ]] call EFUNC(common,log);

    [CRPC(cad,invalidateCadState), []] call CFUNC(globalEvent);
};

GVAR(TaskEventListenerTokens) = [
    EGVAR(common,EventBus) call ["on", ["task.created", _invalidateCadState, "cad.task.invalidate"]],
    EGVAR(common,EventBus) call ["on", ["task.started", _invalidateCadState, "cad.task.invalidate"]],
    EGVAR(common,EventBus) call ["on", ["task.completed", _invalidateCadState, "cad.task.invalidate"]],
    EGVAR(common,EventBus) call ["on", ["task.failed", _invalidateCadState, "cad.task.invalidate"]],
    EGVAR(common,EventBus) call ["on", ["task.cleared", _invalidateCadState, "cad.task.invalidate"]],
    EGVAR(common,EventBus) call ["on", ["cad.assignment.assigned", _invalidateCadAssignmentState, "cad.assignment.invalidate"]],
    EGVAR(common,EventBus) call ["on", ["cad.assignment.created", _invalidateCadAssignmentState, "cad.assignment.invalidate"]],
    EGVAR(common,EventBus) call ["on", ["cad.assignment.acknowledged", _invalidateCadAssignmentState, "cad.assignment.invalidate"]],
    EGVAR(common,EventBus) call ["on", ["cad.assignment.declined", _invalidateCadAssignmentState, "cad.assignment.invalidate"]],
    EGVAR(common,EventBus) call ["on", ["cad.assignment.closed", _invalidateCadAssignmentState, "cad.assignment.invalidate"]],
    EGVAR(common,EventBus) call ["on", ["cad.request.submitted", _invalidateCadRequestState, "cad.request.invalidate"]],
    EGVAR(common,EventBus) call ["on", ["cad.request.closed", _invalidateCadRequestState, "cad.request.invalidate"]],
    EGVAR(common,EventBus) call ["on", ["cad.group.updated", _invalidateCadGroupState, "cad.group.invalidate"]]
];

GVAR(TaskEventListenerTokens)
