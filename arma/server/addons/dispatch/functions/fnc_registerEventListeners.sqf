#include "..\script_component.hpp"

/*
 * File: fnc_registerEventListeners.sqf
 * Author: IDSolutions
 * Date: 2026-11-10
 * Public: No
 *
 * Description:
 * Writes the dispatch activity feed from CAD, task and dispatch events.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Listener tokens [ARRAY]
 *
 * Example:
 * call forge_server_dispatch_fnc_registerEventListeners
 */

if (isNil QEGVAR(common,EventBus)) then { call EFUNC(common,eventBus); };
if !(isNil QGVAR(EventListenerTokens)) exitWith { GVAR(EventListenerTokens) };

private _listeners = [
    ["cad.contract.assigned", {
        params ["_event"];
        private _entry = _event getOrDefault ["entry", createHashMap];
        (GVAR(DispatchStore) get "ActivityLog") call ["append", [
            "contract_assigned",
            format ["%1 assigned %2 to %3.", _entry getOrDefault ["assignedByName", "Dispatch"], _entry getOrDefault ["title", "a contract"], _entry getOrDefault ["assignedGroupCallsign", "a group"]],
            _event getOrDefault ["taskId", ""], _event getOrDefault ["groupId", ""], _entry getOrDefault ["assignedByUid", ""]
        ]];
    }],
    ["cad.contract.accepted", {
        params ["_event"];
        private _entry = _event getOrDefault ["entry", createHashMap];
        (GVAR(DispatchStore) get "ActivityLog") call ["append", [
            "contract_accepted",
            format ["%1 accepted %2.", _entry getOrDefault ["assignedGroupCallsign", "A group"], _entry getOrDefault ["title", "a contract"]],
            _event getOrDefault ["taskId", ""], _event getOrDefault ["groupId", ""], _entry getOrDefault ["requesterUid", ""]
        ]];
    }],
    ["cad.contract.declined", {
        params ["_event"];
        private _entry = _event getOrDefault ["entry", createHashMap];
        (GVAR(DispatchStore) get "ActivityLog") call ["append", [
            "contract_declined",
            format ["%1 declined %2.", _entry getOrDefault ["lastDeclinedGroupCallsign", "A group"], _entry getOrDefault ["title", "a contract"]],
            _event getOrDefault ["taskId", ""], _event getOrDefault ["groupId", ""], _entry getOrDefault ["lastDeclinedByUid", ""]
        ]];
    }],
    ["cad.group.updated", {
        params ["_event"];
        private _group = _event getOrDefault ["group", createHashMap];
        (GVAR(DispatchStore) get "ActivityLog") call ["append", [
            "group_updated",
            format ["%1 is now %2 (%3).", _group getOrDefault ["callsign", "A group"], _group getOrDefault ["status", "?"], _group getOrDefault ["role", "?"]],
            "", _group getOrDefault ["groupId", ""], ""
        ]];
    }],
    ["task.completed", {
        params ["_event"];
        // Dispatch orders log their own close entry.
        if ((_event getOrDefault ["source", ""]) isEqualTo "dispatch") exitWith {};
        (GVAR(DispatchStore) get "ActivityLog") call ["append", [
            "task_completed",
            format ["%1 succeeded.", _event getOrDefault ["title", _event getOrDefault ["taskID", "A task"]]],
            _event getOrDefault ["taskID", ""], "", ""
        ]];
    }],
    ["task.failed", {
        params ["_event"];
        (GVAR(DispatchStore) get "ActivityLog") call ["append", [
            "task_failed",
            format ["%1 failed.", _event getOrDefault ["title", _event getOrDefault ["taskID", "A task"]]],
            _event getOrDefault ["taskID", ""], "", ""
        ]];
    }],
    ["dispatch.order.closed", {
        params ["_event"];
        (GVAR(DispatchStore) get "ActivityLog") call ["append", [
            "dispatch_order_closed",
            _event getOrDefault ["message", "Dispatch order closed."],
            _event getOrDefault ["taskId", ""], "", ""
        ]];
    }],
    ["dispatch.request.submitted", {
        params ["_event"];
        private _request = _event getOrDefault ["request", createHashMap];
        (GVAR(DispatchStore) get "ActivityLog") call ["append", [
            "support_request_submitted",
            format ["%1 submitted %2.", _request getOrDefault ["groupCallsign", "A group"], _request getOrDefault ["title", "a support request"]],
            _request getOrDefault ["requestId", ""], _request getOrDefault ["groupId", ""], _request getOrDefault ["submittedByUid", ""]
        ]];
    }],
    ["dispatch.request.closed", {
        params ["_event"];
        private _request = _event getOrDefault ["request", createHashMap];
        (GVAR(DispatchStore) get "ActivityLog") call ["append", [
            "support_request_closed",
            format ["%1 was closed.", _request getOrDefault ["title", "A support request"]],
            _request getOrDefault ["requestId", ""], _request getOrDefault ["groupId", ""], ""
        ]];
    }]
];

GVAR(EventListenerTokens) = _listeners apply {
    _x params ["_eventName", "_handler"];
    EGVAR(common,EventBus) call ["on", [_eventName, _handler, "dispatch.activity"]]
};

GVAR(EventListenerTokens)
