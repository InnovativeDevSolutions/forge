#include "..\script_component.hpp"

/*
 * File: fnc_initOrderService.sqf
 * Author: IDSolutions
 * Date: 2026-11-10
 * Public: No
 *
 * Description:
 * Initializes the dispatch order service. A dispatch order ("Backup <group>")
 * is a task catalog entry with `source = "dispatch"` and `taskType =
 * "dispatch_order"`. It is assigned, accepted and declined through the normal
 * CAD contract flow; no task handler runs for it. Closing an order marks it
 * succeeded (if it was accepted) and clears it from the catalog.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Order service object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_server_dispatch_fnc_initOrderService
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(OrderServiceBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "DispatchOrderServiceBaseClass"],
    ["#create", compileFinal {
        _self set ["orderSequence", 0];
    }],
    ["isOrder", compileFinal {
        params [["_entry", createHashMap, [createHashMap]]];
        (_entry getOrDefault ["source", ""]) isEqualTo "dispatch"
    }],
    ["create", compileFinal {
        params [
            ["_requesterUid", "", [""]],
            ["_assigneeGroupID", "", [""]],
            ["_targetGroupID", "", [""]],
            ["_note", "", [""]],
            ["_priority", "priority", [""]],
            ["_request", createHashMap, [createHashMap]]
        ];

        private _result = createHashMapFromArray [["success", false], ["message", "Unable to create dispatch order."]];
        private _cadStore = EGVAR(cad,CadStore);
        private _groupRepository = _cadStore get "GroupRepository";

        if !((_cadStore get "PermissionService") call ["canDispatch", [_requesterUid]]) exitWith {
            _result set ["message", "You are not authorized to create dispatch orders."];
            _result
        };
        if (_assigneeGroupID isEqualTo _targetGroupID) exitWith {
            _result set ["message", "Assignee and target groups must be different."];
            _result
        };

        private _target = _groupRepository call ["getGroupRecord", [_targetGroupID]];
        if (_target isEqualTo createHashMap) exitWith {
            _result set ["message", "Selected target group is unavailable."];
            _result
        };

        private _priorityFinal = toLowerANSI _priority;
        if !(_priorityFinal in ["routine", "priority", "emergency"]) then { _priorityFinal = "priority"; };

        private _sequence = (_self getOrDefault ["orderSequence", 0]) + 1;
        _self set ["orderSequence", _sequence];
        private _taskID = format ["dispatch-order:%1", _sequence];
        private _targetCallsign = _target getOrDefault ["callsign", _targetGroupID];
        private _requester = [_requesterUid] call EFUNC(common,getPlayer);

        private _entry = createHashMapFromArray [
            ["type", "dispatch_order"],
            ["taskType", "dispatch_order"],
            ["source", "dispatch"],
            ["title", format ["Backup %1", _targetCallsign]],
            ["description", [_note, format ["Back up %1 at its current position.", _targetCallsign]] select (_note isEqualTo "")],
            ["position", _target getOrDefault ["position", [0, 0, 0]]],
            ["priority", _priorityFinal],
            ["accepted", false],
            ["requesterUid", ""],
            ["orgID", "default"],
            ["prerequisiteTaskIds", []],
            ["targetGroupId", _targetGroupID],
            ["targetGroupCallsign", _targetCallsign],
            ["createdByUid", _requesterUid],
            ["createdByName", ["Dispatcher", name _requester] select !(isNull _requester)],
            ["requestId", _request getOrDefault ["requestId", ""]],
            ["requestType", _request getOrDefault ["type", ""]],
            ["requestTitle", _request getOrDefault ["title", ""]],
            ["requestSummary", _request getOrDefault ["summary", ""]]
        ];

        if !(EGVAR(task,TaskStore) call ["registerTaskCatalogEntry", [_taskID, _entry]]) exitWith {
            _result set ["message", "Task store rejected the dispatch order."];
            _result
        };

        // Assign through CAD so the leader is notified and the contract events fire.
        private _assign = _cadStore call ["assignContract", [_requesterUid, _taskID, _assigneeGroupID, _note]];
        if !(_assign getOrDefault ["success", false]) exitWith {
            EGVAR(task,TaskStore) call ["clearTask", [_taskID]];
            _assign
        };

        _assign set ["message", format ["Dispatch order created: Backup %1.", _targetCallsign]];
        _assign set ["isDispatchOrder", true];
        _assign
    }],
    ["close", compileFinal {
        params [["_requesterUid", "", [""]], ["_taskID", "", [""]]];

        private _result = createHashMapFromArray [["success", false], ["message", "Unable to close dispatch order."]];
        private _cadStore = EGVAR(cad,CadStore);

        if !((_cadStore get "PermissionService") call ["canDispatch", [_requesterUid]]) exitWith {
            _result set ["message", "You are not authorized to close dispatch orders."];
            _result
        };

        private _taskStore = EGVAR(task,TaskStore);
        private _entry = _taskStore call ["getTaskCatalogEntry", [_taskID]];
        if !(_self call ["isOrder", [_entry]]) exitWith {
            _result set ["message", "Dispatch order could not be resolved."];
            _result
        };

        private _wasActive = (_taskStore call ["getTaskStatus", [_taskID]]) isEqualTo "active";
        if (_wasActive) then {
            _taskStore call ["setTaskStatus", [_taskID, "succeeded"]];
        };
        if ([_taskID] call BFUNC(taskExists)) then {
            [_taskID, ["CANCELED", "SUCCEEDED"] select _wasActive, false] call BFUNC(taskSetState);
        };
        _taskStore call ["clearTask", [_taskID]];

        _result set ["success", true];
        _result set ["message", format ["%1 closed.", _entry getOrDefault ["title", "Dispatch order"]]];
        _result set ["taskId", _taskID];
        _result set ["entry", _entry];
        _result set ["isDispatchOrder", true];
        _result
    }],
    ["refreshOrderPositions", compileFinal {
        // Orders follow their target group: update title/position in place
        // on the hydrate payload's contracts.
        params [["_payload", createHashMap, [createHashMap]]];

        private _groupsById = createHashMap;
        { _groupsById set [_x getOrDefault ["groupId", ""], _x]; } forEach (_payload getOrDefault ["groups", []]);

        {
            if !(_x getOrDefault ["isDispatchOrder", false]) then { continue; };

            private _target = _groupsById getOrDefault [_x getOrDefault ["targetGroupId", ""], createHashMap];
            if (_target isEqualTo createHashMap) then { continue; };

            _x set ["position", _target getOrDefault ["position", _x getOrDefault ["position", []]]];
            _x set ["targetGroupCallsign", _target getOrDefault ["callsign", _x getOrDefault ["targetGroupCallsign", ""]]];
        } forEach (_payload getOrDefault ["contracts", []]);

        true
    }]
];

createHashMapObject [GVAR(OrderServiceBaseClass)]
