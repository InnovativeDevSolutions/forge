#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Server side task handler/spawner
 *
 * Arguments:
 * 0: Type of task <STRING>
 * 1: Arguments for task <ARRAY>
 * 2: Minimum org reputation for task <NUMBER> (default: 0)
 * 3: Requester UID <STRING> (default: "")
 *
 * Return Value:
 * None
 *
 * Example:
 * ["task_type", [_reward, _punish, _time, etc.....], minReputation, requesterUid] call forge_server_task_fnc_handler;
 *
 * Public: Yes
 */

params [["_taskType", "", [""]], ["_args", [], [[]]], ["_minRating", 0, [0]], ["_requesterUid", "", [""]]];

private _taskID = "";

if (_minRating > 0) then {
    if (_requesterUid isEqualTo "") then {
        ["WARNING", format ["Task %1 requires minimum reputation %2 but no requester UID was provided, skipping reputation gate.", _taskType, _minRating]] call EFUNC(common,log);
    } else {
        private _orgID = EGVAR(actor,ActorStore) call ["getOrganization", [_requesterUid]];
        private _org = EGVAR(org,OrgStore) call ["loadById", [_orgID]];
        private _orgReputation = _org getOrDefault ["reputation", 0];
        if (_orgReputation < _minRating) exitWith {
            private _message = format ["Organization reputation of %1 does not meet the minimum required reputation of %2.", _orgReputation, _minRating];
            ["WARNING", format ["Task %1 blocked: %2", _taskType, _message]] call EFUNC(common,log);

            private _player = [_requesterUid] call EFUNC(common,getPlayer);
            if (isNull _player) exitWith {};

            [CRPC(notifications,recieveNotification), ["warning", "Tasks", _message], _player] call CFUNC(targetEvent);
        };
    };
};

if (_args isNotEqualTo [] && { (_args select 0) isEqualType "" }) then {
    _taskID = _args select 0;
};

if (_taskID isNotEqualTo "") then {
    private _catalogEntry = GVAR(TaskStore) call ["getTaskCatalogEntry", [_taskID]];
    private _source = if (_catalogEntry isEqualType createHashMap) then {
        _catalogEntry getOrDefault ["source", ""]
    } else {
        ""
    };

    if (_requesterUid isNotEqualTo "" || { _source isNotEqualTo "mission_manager" }) then {
        private _ownershipResult = GVAR(TaskStore) call ["bindTaskOwnership", [_taskID, _requesterUid]];
        if !(_ownershipResult getOrDefault ["success", false]) then {
            ["WARNING", format [
                "Failed to bind task ownership for %1 (%2): %3",
                _taskID,
                _taskType,
                _ownershipResult getOrDefault ["message", "Unknown error."]
            ]] call EFUNC(common,log);
        };
    } else {
        ["INFO", format [
            "Skipped automatic ownership bind for generated mission %1 so it remains unaccepted until a player accepts it.",
            _taskID
        ]] call EFUNC(common,log);
    };

    GVAR(TaskStore) call ["setTaskStatus", [_taskID, "active"]];
};

switch (_taskType) do {
	case "attack": {
		private _thread = _args spawn FUNC(attack);
		waitUntil { sleep 2; scriptDone _thread };
	};
	case "defuse": {
		private _thread = _args spawn FUNC(defuse);
		waitUntil { sleep 2; scriptDone _thread };
	};
	case "destroy": {
		private _thread = _args spawn FUNC(destroy);
		waitUntil { sleep 2; scriptDone _thread };
	};
	case "delivery": {
		private _thread = _args spawn FUNC(delivery);
		waitUntil { sleep 2; scriptDone _thread };
	};
	case "defend": {
		private _thread = _args spawn FUNC(defend);
		waitUntil { sleep 2; scriptDone _thread };
	};
	case "hostage": {
		private _thread = _args spawn FUNC(hostage);
		waitUntil { sleep 2; scriptDone _thread };
	};
	case "hvt": {
		private _thread = _args spawn FUNC(hvt);
		waitUntil { sleep 2; scriptDone _thread };
	};
	default {
        ["ERROR", format ["Unknown Contract Type: %1", _taskType]] call EFUNC(common,log);
    };
};

["INFO", "Mission Handler Done"] call EFUNC(common,log);
