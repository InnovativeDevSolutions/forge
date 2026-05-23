#include "..\script_component.hpp"

/*
 * File: fnc_initRequestRepository.sqf
 * Author: IDSolutions
 * Date: 2026-03-31
 * Public: No
 *
 * Description:
 * Initializes the CAD request repository for structured support
 * requests submitted by groups and triaged by dispatch.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * CAD request repository object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_server_cad_fnc_initRequestRepository
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(RequestRepositoryBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "CadRequestRepositoryBaseClass"],
    ["#create", compileFinal {
        _self set ["validTypes", [
            "medevac_9line",
            "ace_lace",
            "fire_support",
            "air_support",
            "logreq"
        ]];
        _self set ["validPriorities", [
            "routine",
            "priority",
            "emergency"
        ]];
    }],
    ["loadRequestRegistry", compileFinal {
        private _persistenceService = _self getOrDefault ["persistenceService", createHashMap];
        if (_persistenceService isEqualTo createHashMap) exitWith { createHashMap };

        private _result = _persistenceService call ["loadRequests", []];
        if !(_result getOrDefault ["success", false]) exitWith { createHashMap };

        +(_result getOrDefault ["data", createHashMap])
    }],
    ["submitRequest", compileFinal {
        params [
            ["_requesterUid", "", [""]],
            ["_type", "", [""]],
            ["_fields", createHashMap, [createHashMap]],
            ["_priority", "priority", [""]]
        ];

        private _result = createHashMapFromArray [
            ["success", false],
            ["message", "Unable to submit support request."],
            ["request", createHashMap]
        ];

        private _finalType = toLowerANSI _type;
        if !(_finalType in (_self getOrDefault ["validTypes", []])) exitWith {
            _result set ["message", "Invalid support request type."];
            _result
        };

        private _groupRepository = _self getOrDefault ["groupRepository", createHashMap];
        private _groupID = _groupRepository call ["getPlayerGroupId", [_requesterUid]];
        if (_groupID isEqualTo "") exitWith {
            _result set ["message", "You are not currently assigned to a group."];
            _result
        };

        if !(_groupRepository call ["isGroupLeader", [_requesterUid, _groupID]]) exitWith {
            _result set ["message", "Only the current group leader can submit support requests."];
            _result
        };

        private _groupRecord = _groupRepository call ["getGroupRecord", [_groupID]];
        if (_groupRecord isEqualTo createHashMap) exitWith {
            _result set ["message", "Your group could not be resolved."];
            _result
        };

        private _validPriorities = _self getOrDefault ["validPriorities", []];
        private _finalPriority = toLowerANSI _priority;
        if !(_finalPriority in _validPriorities) then {
            _finalPriority = "priority";
        };

        private _requestContext = createHashMapFromArray [
            ["type", _finalType],
            ["fields", +_fields],
            ["groupId", _groupID],
            ["groupCallsign", _groupRecord getOrDefault ["callsign", _groupID]],
            ["submittedByUid", _requesterUid],
            ["submittedByName", _groupRecord getOrDefault ["leaderName", _requesterUid]],
            ["priority", _finalPriority],
            ["position", +(_groupRecord getOrDefault ["position", []])],
            ["createdAt", serverTime]
        ];

        private _persistenceService = _self getOrDefault ["persistenceService", createHashMap];
        if (_persistenceService isEqualTo createHashMap) exitWith {
            _result set ["message", "CAD extension state is unavailable."];
            _result
        };

        private _submitResult = _persistenceService call ["submitSupportRequestFromContext", [_requestContext]];
        if !(_submitResult getOrDefault ["success", false]) exitWith {
            _result set ["message", "CAD extension rejected the support request."];
            _result
        };

        private _submitData = +(_submitResult getOrDefault ["data", createHashMap]);
        private _request = +(_submitData getOrDefault ["request", createHashMap]);
        private _requestID = _request getOrDefault ["requestId", ""];
        if (_requestID isEqualTo "") exitWith {
            _result set ["message", "CAD extension returned an invalid support request."];
            _result
        };

        private _activityEntry = +(_submitData getOrDefault ["activity", createHashMap]);
        if (_activityEntry isNotEqualTo createHashMap) then {
            private _activityRepository = _self getOrDefault ["activityRepository", createHashMap];
            _activityRepository call ["appendEntry", [_activityEntry]];
        };

        _result set ["success", true];
        _result set ["message", _submitData getOrDefault ["message", "Support request submitted."]];
        _result set ["request", _request];
        _result
    }],
    ["closeRequest", compileFinal {
        params [["_requesterUid", "", [""]], ["_requestID", "", [""]]];

        private _result = createHashMapFromArray [
            ["success", false],
            ["message", "Unable to close support request."],
            ["request", createHashMap]
        ];

        private _requestRegistry = _self call ["loadRequestRegistry", []];
        private _request = +(_requestRegistry getOrDefault [_requestID, createHashMap]);
        if (_request isEqualTo createHashMap) exitWith {
            _result set ["message", "Support request could not be resolved."];
            _result
        };

        private _permissionService = _self getOrDefault ["permissionService", createHashMap];
        private _groupRepository = _self getOrDefault ["groupRepository", createHashMap];
        private _groupID = _request getOrDefault ["groupId", ""];
        private _isAuthorized = (_permissionService call ["canDispatch", [_requesterUid]]) || { _groupRepository call ["isGroupLeader", [_requesterUid, _groupID]] };
        if !_isAuthorized exitWith {
            _result set ["message", "You are not authorized to close that support request."];
            _result
        };

        private _persistenceService = _self getOrDefault ["persistenceService", createHashMap];
        if (_persistenceService isEqualTo createHashMap) exitWith {
            _result set ["message", "CAD extension state is unavailable."];
            _result
        };

        private _closeResult = _persistenceService call ["closeSupportRequest", [_requestID]];
        if !(_closeResult getOrDefault ["success", false]) exitWith {
            _result set ["message", "CAD extension rejected the support request close."];
            _result
        };

        private _closeData = +(_closeResult getOrDefault ["data", createHashMap]);
        _request = +(_closeData getOrDefault ["request", _request]);

        private _activityEntry = +(_closeData getOrDefault ["activity", createHashMap]);
        if (_activityEntry isNotEqualTo createHashMap) then {
            _activityEntry set ["actorUid", _requesterUid];
            private _activityRepository = _self getOrDefault ["activityRepository", createHashMap];
            _activityRepository call ["appendEntry", [_activityEntry]];
        };

        _result set ["success", true];
        _result set ["message", _closeData getOrDefault ["message", "Support request closed."]];
        _result set ["request", _request];
        _result
    }]
];

createHashMapObject [GVAR(RequestRepositoryBaseClass)]
