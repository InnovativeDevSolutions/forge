#include "..\script_component.hpp"

/*
 * File: fnc_initRequestService.sqf
 * Author: IDSolutions
 * Date: 2026-03-31
 * Public: No
 *
 * Description:
 * Initializes the dispatch support request service. Group leaders submit
 * structured requests (9-line MEDEVAC, ACE/LACE, fire/air support, LOGREQ);
 * dispatchers triage them and can turn them into dispatch orders.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Request service object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_server_dispatch_fnc_initRequestService
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(RequestServiceBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "DispatchRequestServiceBaseClass"],
    ["callExtension", compileFinal {
        params [["_function", "", [""]], ["_arguments", [], [[]]]];

        [_function, _arguments] call EFUNC(extension,extCall) params ["_payload", "_isSuccess"];
        if (!_isSuccess || { !(_payload isEqualType "") }) exitWith { [false, "Dispatch extension call failed."] };
        if ((_payload find "Error:") == 0) exitWith { [false, _payload select [7]] };

        private _data = fromJSON _payload;
        if (isNil "_data") exitWith { [false, "Not found."] };
        [true, _data]
    }],
    ["list", compileFinal {
        (_self call ["callExtension", ["dispatch:requests:list", []]]) params ["_ok", "_data"];
        if (!_ok || { !(_data isEqualType []) }) exitWith { [] };
        _data
    }],
    ["submit", compileFinal {
        params [
            ["_requesterUid", "", [""]],
            ["_type", "", [""]],
            ["_fields", createHashMap, [createHashMap]],
            ["_priority", "priority", [""]]
        ];

        private _result = createHashMapFromArray [["success", false], ["message", "Unable to submit support request."]];

        private _groupRepository = EGVAR(cad,CadStore) get "GroupRepository";
        private _groupID = _groupRepository call ["getPlayerGroupId", [_requesterUid]];
        if (_groupID isEqualTo "") exitWith {
            _result set ["message", "You are not currently in a tracked group."];
            _result
        };
        if !(_groupRepository call ["isGroupLeader", [_requesterUid, _groupID]]) exitWith {
            _result set ["message", "Only the current group leader can submit support requests."];
            _result
        };

        private _group = _groupRepository call ["getGroupRecord", [_groupID]];
        private _seed = createHashMapFromArray [
            ["type", toLowerANSI _type],
            ["fields", +_fields],
            ["groupId", _groupID],
            ["groupCallsign", _group getOrDefault ["callsign", _groupID]],
            ["submittedByUid", _requesterUid],
            ["submittedByName", _group getOrDefault ["leaderName", ""]],
            ["priority", _priority],
            ["position", _group getOrDefault ["position", []]],
            ["createdAt", serverTime]
        ];

        (_self call ["callExtension", ["dispatch:requests:submit", [toJSON _seed]]]) params ["_ok", "_data"];
        if !_ok exitWith {
            _result set ["message", _data];
            _result
        };

        _result set ["success", true];
        _result set ["message", _data getOrDefault ["message", "Support request submitted."]];
        _result set ["request", _data getOrDefault ["request", createHashMap]];
        _result
    }],
    ["close", compileFinal {
        params [["_requesterUid", "", [""]], ["_requestID", "", [""]]];

        private _result = createHashMapFromArray [["success", false], ["message", "Unable to close support request."]];

        (_self call ["callExtension", ["dispatch:requests:get", [_requestID]]]) params ["_ok", "_request"];
        if (!_ok || { !(_request isEqualType createHashMap) }) exitWith {
            _result set ["message", "Support request could not be resolved."];
            _result
        };

        private _cadStore = EGVAR(cad,CadStore);
        private _isAuthorized = ((_cadStore get "PermissionService") call ["canDispatch", [_requesterUid]])
            || { (_cadStore get "GroupRepository") call ["isGroupLeader", [_requesterUid, _request getOrDefault ["groupId", ""]]] };
        if !_isAuthorized exitWith {
            _result set ["message", "You are not authorized to close that support request."];
            _result
        };

        (_self call ["callExtension", ["dispatch:requests:close", [_requestID]]]) params ["_closed", "_data"];
        if !_closed exitWith {
            _result set ["message", _data];
            _result
        };

        _result set ["success", true];
        _result set ["message", _data getOrDefault ["message", "Support request closed."]];
        _result set ["request", _data getOrDefault ["request", _request]];
        _result
    }]
];

createHashMapObject [GVAR(RequestServiceBaseClass)]
