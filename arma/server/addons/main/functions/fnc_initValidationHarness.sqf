#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Initializes the server-side validation harness for targeted runtime smoke
 * checks around high-risk multi-module flows.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Validation harness object <HASHMAP OBJECT>
 *
 * Example:
 * call forge_server_main_fnc_initValidationHarness;
 *
 * Public: No
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(ValidationHarness) = createHashMapObject [[
    ["#type", "ValidationHarness"],
    ["buildResult", compileFinal {
        params [
            ["_action", "", [""]],
            ["_success", false, [false]],
            ["_message", "", [""]],
            ["_data", createHashMap, [createHashMap]]
        ];

        createHashMapFromArray [
            ["action", _action],
            ["success", _success],
            ["message", _message],
            ["data", _data]
        ]
    }],
    ["logResult", compileFinal {
        params [["_result", createHashMap, [createHashMap]]];

        if (_result isEqualTo createHashMap) exitWith { _result };

        private _level = ["WARNING", "INFO"] select (_result getOrDefault ["success", false]);
        private _action = _result getOrDefault ["action", "validation"];
        private _message = _result getOrDefault ["message", ""];
        [_level, format ["Validation harness '%1': %2", _action, _message]] call EFUNC(common,log);

        _result
    }],
    ["normalizeMapArg", compileFinal {
        params [
            ["_value", createHashMap, [createHashMap, ""]],
            ["_fallback", createHashMap, [createHashMap]]
        ];

        if (_value isEqualType createHashMap) exitWith { +_value };
        if !(_value isEqualType "") exitWith { +_fallback };
        if (_value isEqualTo "") exitWith { +_fallback };

        private _parsed = fromJSON _value;
        if !(_parsed isEqualType createHashMap) exitWith { +_fallback };

        _parsed
    }],
    ["run", compileFinal {
        params [["_action", "", [""]], ["_arguments", [], [[]]]];

        private _actionLower = toLowerANSI _action;
        if (_actionLower isEqualTo "") exitWith {
            _self call ["logResult", [_self call ["buildResult", ["unknown", false, "A validation action is required.", createHashMap]]]]
        };

        switch (_actionLower) do {
            case "save_hot_state": {
                _arguments params [["_uid", "", [""]]];

                private _success = [_uid] call FUNC(saveHotState);
                private _message = [
                    format ["Hot-state save failed for '%1'.", _uid],
                    format ["Hot-state save completed for '%1'.", [_uid, "all hot state"] select (_uid isEqualTo "")]
                ] select _success;

                _self call ["logResult", [_self call ["buildResult", [
                    _actionLower,
                    _success,
                    _message,
                    createHashMapFromArray [["uid", _uid]]
                ]]]]
            };
            case "store_checkout": {
                _arguments params [["_uid", "", [""]], ["_payload", createHashMap, [createHashMap, ""]]];

                private _player = [_uid] call EFUNC(common,getPlayer);
                if (_uid isEqualTo "" || { isNull _player }) exitWith {
                    _self call ["logResult", [_self call ["buildResult", [_actionLower, false, "A valid online player UID is required for store checkout validation.", createHashMap]]]]
                };

                private _payloadMap = _self call ["normalizeMapArg", [_payload, createHashMap]];
                if (_payloadMap isEqualTo createHashMap) exitWith {
                    _self call ["logResult", [_self call ["buildResult", [_actionLower, false, "Store checkout validation payload was invalid.", createHashMap]]]]
                };

                private _result = EGVAR(store,StorefrontStore) call ["checkout", [_uid, _player, toJSON _payloadMap]];
                private _success = _result getOrDefault ["success", false];
                private _message = _result getOrDefault ["message", "Store checkout validation completed."];

                _self call ["logResult", [_self call ["buildResult", [_actionLower, _success, _message, _result]]]]
            };
            case "org_assign_credit_line": {
                _arguments params [
                    ["_requesterUid", "", [""]],
                    ["_memberUid", "", [""]],
                    ["_memberName", "", [""]],
                    ["_amount", 0, [0]]
                ];

                private _result = EGVAR(org,OrgStore) call ["assignCreditLine", [_requesterUid, _memberUid, _memberName, _amount]];
                private _success = _result getOrDefault ["success", false];
                private _message = _result getOrDefault ["message", "Credit line validation completed."];

                _self call ["logResult", [_self call ["buildResult", [_actionLower, _success, _message, _result]]]]
            };
            case "bank_credit_repayment": {
                _arguments params [["_uid", "", [""]], ["_amount", 0, [0]]];

                if (_uid isEqualTo "") exitWith {
                    _self call ["logResult", [_self call ["buildResult", [_actionLower, false, "A valid UID is required for bank credit repayment validation.", createHashMap]]]]
                };

                private _beforeAccount = EGVAR(bank,BankStore) call ["get", [_uid, ""]];
                private _beforeOrgState = EGVAR(bank,BankPayloadBuilder) call ["resolveOrgState", [_uid]];
                private _success = EGVAR(bank,BankStore) call ["repayCreditLine", [_uid, _amount]];
                private _afterAccount = EGVAR(bank,BankStore) call ["get", [_uid, ""]];
                private _afterOrgState = EGVAR(bank,BankPayloadBuilder) call ["resolveOrgState", [_uid]];

                private _message = [
                    format ["Bank credit repayment validation failed for %1.", _uid],
                    format ["Bank credit repayment validation completed for %1.", _uid]
                ] select _success;

                _self call ["logResult", [_self call ["buildResult", [
                    _actionLower,
                    _success,
                    _message,
                    createHashMapFromArray [
                        ["beforeAccount", _beforeAccount],
                        ["afterAccount", _afterAccount],
                        ["beforeOrgState", _beforeOrgState],
                        ["afterOrgState", _afterOrgState]
                    ]
                ]]]]
            };
            case "task_reward_context": {
                _arguments params [["_taskID", "", [""]]];

                private _context = EGVAR(task,TaskStore) call ["resolveRewardContext", [_taskID]];
                private _success = _taskID isNotEqualTo "" && { (_context getOrDefault ["orgID", ""]) isNotEqualTo "" };
                private _message = [
                    format ["No reward context was available for task %1.", _taskID],
                    format ["Resolved reward context for task %1.", _taskID]
                ] select _success;

                _self call ["logResult", [_self call ["buildResult", [_actionLower, _success, _message, _context]]]]
            };
            case "task_apply_rating": {
                _arguments params [["_taskID", "", [""]], ["_delta", 0, [0]]];

                private _result = EGVAR(task,TaskStore) call ["applyRatingOutcome", [_taskID, _delta]];
                private _success = _result getOrDefault ["success", true];
                private _message = [
                    _result getOrDefault ["message", format ["Task rating validation failed for %1.", _taskID]],
                    format ["Task rating validation completed for %1.", _taskID]
                ] select _success;

                _self call ["logResult", [_self call ["buildResult", [_actionLower, _success, _message, _result]]]]
            };
            case "task_apply_rewards": {
                _arguments params [["_taskID", "", [""]], ["_rewards", createHashMap, [createHashMap, ""]]];

                private _rewardsMap = _self call ["normalizeMapArg", [_rewards, createHashMap]];
                if (_taskID isEqualTo "" || { _rewardsMap isEqualTo createHashMap }) exitWith {
                    _self call ["logResult", [_self call ["buildResult", [_actionLower, false, "Task reward validation requires a task ID and reward payload.", createHashMap]]]]
                };

                private _rewardContext = EGVAR(task,TaskStore) call ["resolveRewardContext", [_taskID]];
                private _beforeOrg = EGVAR(org,OrgStore) call ["loadById", [_rewardContext getOrDefault ["orgID", ""]]];
                private _success = [_taskID, _rewardsMap] call EFUNC(task,handleTaskRewards);
                private _afterOrg = EGVAR(org,OrgStore) call ["loadById", [_rewardContext getOrDefault ["orgID", ""]]];

                private _message = [
                    format ["Task reward validation failed for %1.", _taskID],
                    format ["Task reward validation completed for %1.", _taskID]
                ] select _success;

                _self call ["logResult", [_self call ["buildResult", [
                    _actionLower,
                    _success,
                    _message,
                    createHashMapFromArray [
                        ["rewardContext", _rewardContext],
                        ["beforeOrg", _beforeOrg],
                        ["afterOrg", _afterOrg]
                    ]
                ]]]]
            };
            default {
                _self call ["logResult", [_self call ["buildResult", [_actionLower, false, format ["Unknown validation action '%1'.", _actionLower], createHashMap]]]]
            };
        };
    }]
]];

GVAR(ValidationHarness)
