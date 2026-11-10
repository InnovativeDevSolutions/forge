#include "..\script_component.hpp"

/*
 * File: fnc_initContractService.sqf
 * Author: IDSolutions
 * Date: 2026-11-10
 * Public: No
 *
 * Description:
 * Initializes the CAD contract service. Contracts are task catalog entries;
 * this service only checks who may act and delegates the state change to
 * TaskStore, which owns the lifecycle:
 *
 *   available --assign (dispatcher)--> assigned --accept (group leader)--> active
 *                                      assigned --decline (group leader)--> available
 *
 * Arguments:
 * None
 *
 * Return Value:
 * CAD contract service object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_server_cad_fnc_initContractService
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(ContractServiceBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "CadContractServiceBaseClass"],
    ["resolvePlayerName", compileFinal {
        params [["_uid", "", [""]], ["_fallback", "Unknown", [""]]];

        private _player = [_uid] call EFUNC(common,getPlayer);
        if (isNull _player) exitWith { _fallback };
        name _player
    }],
    ["assign", compileFinal {
        params [
            ["_requesterUid", "", [""]],
            ["_taskID", "", [""]],
            ["_groupID", "", [""]],
            ["_note", "", [""]]
        ];

        private _result = createHashMapFromArray [
            ["success", false],
            ["message", "Unable to assign contract."]
        ];

        if !((_self get "permissionService") call ["canDispatch", [_requesterUid]]) exitWith {
            _result set ["message", "You are not authorized to assign contracts."];
            _result
        };

        private _groupRepository = _self get "groupRepository";
        private _group = _groupRepository call ["findGroup", [_groupID]];
        if !(_groupRepository call ["isTrackedGroup", [_group]]) exitWith {
            _result set ["message", "Selected group is unavailable."];
            _result
        };

        private _leader = _groupRepository call ["resolveLeader", [_group]];
        if (isNull _leader) exitWith {
            _result set ["message", "Selected group has no online leader."];
            _result
        };

        private _callsign = [groupId _group, _groupID] select ((groupId _group) isEqualTo "");
        _result = EGVAR(task,TaskStore) call ["assignTaskToGroup", [
            _taskID,
            _groupID,
            _callsign,
            _requesterUid,
            _self call ["resolvePlayerName", [_requesterUid, "Dispatcher"]],
            _note
        ]];

        _result set ["taskId", _taskID];
        _result set ["groupId", _groupID];
        _result set ["leaderUid", getPlayerUID _leader];
        _result
    }],
    ["resolveAssignedGroup", compileFinal {
        params [["_requesterUid", "", [""]], ["_taskID", "", [""]], ["_action", "update", [""]]];

        private _entry = EGVAR(task,TaskStore) call ["getTaskCatalogEntry", [_taskID]];
        private _groupID = _entry getOrDefault ["assignedGroupId", ""];
        if (_groupID isEqualTo "") exitWith { [_entry, "", "Contract is not assigned to a group."] };

        if !((_self get "groupRepository") call ["isGroupLeader", [_requesterUid, _groupID]]) exitWith {
            [_entry, "", format ["Only the assigned group leader can %1 this contract.", _action]]
        };

        [_entry, _groupID, ""]
    }],
    ["accept", compileFinal {
        params [["_requesterUid", "", [""]], ["_taskID", "", [""]]];

        (_self call ["resolveAssignedGroup", [_requesterUid, _taskID, "accept"]]) params ["_entry", "_groupID", "_error"];
        if (_error isNotEqualTo "") exitWith {
            createHashMapFromArray [["success", false], ["message", _error]]
        };

        private _result = EGVAR(task,TaskStore) call ["acceptTaskForGroup", [
            _taskID,
            _groupID,
            _requesterUid,
            _self call ["resolvePlayerName", [_requesterUid]]
        ]];

        _result set ["taskId", _taskID];
        _result set ["groupId", _groupID];
        _result set ["dispatcherUid", _entry getOrDefault ["assignedByUid", ""]];
        _result
    }],
    ["decline", compileFinal {
        params [["_requesterUid", "", [""]], ["_taskID", "", [""]]];

        (_self call ["resolveAssignedGroup", [_requesterUid, _taskID, "decline"]]) params ["_entry", "_groupID", "_error"];
        if (_error isNotEqualTo "") exitWith {
            createHashMapFromArray [["success", false], ["message", _error]]
        };

        private _result = EGVAR(task,TaskStore) call ["declineTaskForGroup", [
            _taskID,
            _groupID,
            _requesterUid,
            _self call ["resolvePlayerName", [_requesterUid]]
        ]];

        _result set ["taskId", _taskID];
        _result set ["groupId", _groupID];
        _result set ["dispatcherUid", _entry getOrDefault ["assignedByUid", ""]];
        _result
    }]
];

createHashMapObject [GVAR(ContractServiceBaseClass)]
