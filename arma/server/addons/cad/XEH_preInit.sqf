#include "script_component.hpp"

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

call FUNC(initCadStore);
call FUNC(registerEventListeners);

[QGVAR(requestHydrateCad), {
    params [["_uid", "", [""]]];

    private _player = GVAR(CadStore) call ["resolveRequestPlayer", [_uid, "CAD hydrate request received with empty UID."]];
    if (_player isEqualTo objNull) exitWith {};

    private _payload = GVAR(CadStore) call ["buildHydratePayload", [_uid]];
    [CRPC(cad,responseHydrateCad), [_payload], _player] call CFUNC(targetEvent);
}] call CFUNC(addEventHandler);

[QGVAR(requestAssignCadTask), {
    params [
        ["_uid", "", [""]],
        ["_taskID", "", [""]],
        ["_groupID", "", [""]],
        ["_note", "", [""]]
    ];

    if (_taskID isEqualTo "" || { _groupID isEqualTo "" }) exitWith {
        ["WARNING", "Invalid CAD task assignment payload."] call EFUNC(common,log);
    };

    GVAR(CadStore) call ["dispatchRpcMutation", [
        _uid,
        "Invalid CAD task assignment payload.",
        CRPC(cad,responseCadAssignment),
        "assignTaskToGroup",
        [_uid, _taskID, _groupID, _note],
        false,
        false
    ]];
}] call CFUNC(addEventHandler);

[QGVAR(requestCreateCadDispatchOrder), {
    params [
        ["_uid", "", [""]],
        ["_assigneeGroupID", "", [""]],
        ["_targetGroupID", "", [""]],
        ["_note", "", [""]],
        ["_priority", "priority", [""]],
        ["_request", createHashMap, [createHashMap]]
    ];

    if (_assigneeGroupID isEqualTo "" || { _targetGroupID isEqualTo "" }) exitWith {
        ["WARNING", "Invalid CAD dispatch order payload."] call EFUNC(common,log);
    };

    GVAR(CadStore) call ["dispatchRpcMutation", [
        _uid,
        "Invalid CAD dispatch order payload.",
        CRPC(cad,responseCadAssignment),
        "createDispatchOrder",
        [_uid, _assigneeGroupID, _targetGroupID, _note, _priority, _request],
        false,
        false
    ]];
}] call CFUNC(addEventHandler);

[QGVAR(requestGenerateCadMissionTask), {
    params [
        ["_uid", "", [""]],
        ["_taskType", "", [""]],
        ["_metadata", createHashMap, [createHashMap]]
    ];

    private _player = GVAR(CadStore) call ["resolveRequestPlayer", [_uid, "Invalid CAD generated task payload."]];
    if (_player isEqualTo objNull) exitWith {};

    private _result = createHashMapFromArray [
        ["success", false],
        ["message", "Generated task request failed."]
    ];

    if (_taskType isEqualTo "") exitWith {
        _result set ["message", "Select a task type before requesting a generated task."];
        [CRPC(cad,responseCadRequest), [_result], _player] call CFUNC(targetEvent);
    };

    private _permissionService = GVAR(CadStore) getOrDefault ["PermissionService", createHashMap];
    if (_permissionService isEqualTo createHashMap || { !(_permissionService call ["canDispatch", [_uid]]) }) exitWith {
        _result set ["message", "Only dispatchers can request generated tasks."];
        [CRPC(cad,responseCadRequest), [_result], _player] call CFUNC(targetEvent);
    };

    if (isNil "forge_pmc_fnc_requestMissionTask") exitWith {
        _result set ["message", "This mission does not expose dispatcher-generated tasks."];
        [CRPC(cad,responseCadRequest), [_result], _player] call CFUNC(targetEvent);
    };

    // Temporary mission-owned integration point. This keeps simulator-specific
    // generator logic in the mission until CAD/task grows a framework-level
    // on-demand generation interface.
    _result = [_taskType, _metadata, _uid] call forge_pmc_fnc_requestMissionTask;
    [CRPC(cad,responseCadRequest), [_result], _player] call CFUNC(targetEvent);

    if (_result getOrDefault ["success", false]) then {
        [CRPC(cad,invalidateCadState), []] call CFUNC(globalEvent);
    };
}] call CFUNC(addEventHandler);

[QGVAR(requestSubmitCadSupportRequest), {
    params [
        ["_uid", "", [""]],
        ["_type", "", [""]],
        ["_fields", createHashMap, [createHashMap]],
        ["_priority", "priority", [""]]
    ];

    if (_type isEqualTo "") exitWith {
        ["WARNING", "Invalid CAD support request payload."] call EFUNC(common,log);
    };

    GVAR(CadStore) call ["dispatchRpcMutation", [
        _uid,
        "Invalid CAD support request payload.",
        CRPC(cad,responseCadRequest),
        "submitSupportRequest",
        [_uid, _type, _fields, _priority],
        false,
        false
    ]];
}] call CFUNC(addEventHandler);

[QGVAR(requestCloseCadSupportRequest), {
    params [["_uid", "", [""]], ["_requestID", "", [""]]];

    if (_requestID isEqualTo "") exitWith {
        ["WARNING", "Invalid CAD support request close payload."] call EFUNC(common,log);
    };

    GVAR(CadStore) call ["dispatchRpcMutation", [
        _uid,
        "Invalid CAD support request close payload.",
        CRPC(cad,responseCadRequest),
        "closeSupportRequest",
        [_uid, _requestID],
        false,
        false
    ]];
}] call CFUNC(addEventHandler);

[QGVAR(requestAcknowledgeCadTask), {
    params [["_uid", "", [""]], ["_taskID", "", [""]]];

    if (_taskID isEqualTo "") exitWith {
        ["WARNING", "Invalid CAD acknowledge payload."] call EFUNC(common,log);
    };

    GVAR(CadStore) call ["dispatchRpcMutation", [
        _uid,
        "Invalid CAD acknowledge payload.",
        CRPC(cad,responseCadAssignment),
        "acknowledgeTask",
        [_uid, _taskID],
        false,
        false
    ]];
}] call CFUNC(addEventHandler);

[QGVAR(requestCloseCadDispatchOrder), {
    params [["_uid", "", [""]], ["_taskID", "", [""]]];

    if (_taskID isEqualTo "") exitWith {
        ["WARNING", "Invalid CAD dispatch order close payload."] call EFUNC(common,log);
    };

    GVAR(CadStore) call ["dispatchRpcMutation", [
        _uid,
        "Invalid CAD dispatch order close payload.",
        CRPC(cad,responseCadAssignment),
        "closeDispatchOrder",
        [_uid, _taskID],
        false,
        false
    ]];
}] call CFUNC(addEventHandler);

[QGVAR(requestDeclineCadTask), {
    params [["_uid", "", [""]], ["_taskID", "", [""]]];

    if (_taskID isEqualTo "") exitWith {
        ["WARNING", "Invalid CAD decline payload."] call EFUNC(common,log);
    };

    GVAR(CadStore) call ["dispatchRpcMutation", [
        _uid,
        "Invalid CAD decline payload.",
        CRPC(cad,responseCadAssignment),
        "declineTask",
        [_uid, _taskID],
        false,
        false
    ]];
}] call CFUNC(addEventHandler);

[QGVAR(requestUpdateCadGroupStatus), {
    params [["_uid", "", [""]], ["_groupID", "", [""]], ["_status", "", [""]]];

    if (_groupID isEqualTo "" || { _status isEqualTo "" }) exitWith {
        ["WARNING", "Invalid CAD group status payload."] call EFUNC(common,log);
    };

    GVAR(CadStore) call ["dispatchRpcMutation", [
        _uid,
        "Invalid CAD group status payload.",
        CRPC(cad,responseCadGroupUpdate),
        "updateGroupStatus",
        [_uid, _groupID, _status],
        false,
        true
    ]];
}] call CFUNC(addEventHandler);

[QGVAR(requestUpdateCadGroupRole), {
    params [["_uid", "", [""]], ["_groupID", "", [""]], ["_role", "", [""]]];

    if (_groupID isEqualTo "" || { _role isEqualTo "" }) exitWith {
        ["WARNING", "Invalid CAD group role payload."] call EFUNC(common,log);
    };

    GVAR(CadStore) call ["dispatchRpcMutation", [
        _uid,
        "Invalid CAD group role payload.",
        CRPC(cad,responseCadGroupUpdate),
        "updateGroupRole",
        [_uid, _groupID, _role],
        false,
        true
    ]];
}] call CFUNC(addEventHandler);

[QGVAR(requestUpdateCadGroupProfile), {
    params [
        ["_uid", "", [""]],
        ["_groupID", "", [""]],
        ["_status", "", [""]],
        ["_role", "", [""]]
    ];

    if (_groupID isEqualTo "") exitWith {
        ["WARNING", "Invalid CAD group profile payload."] call EFUNC(common,log);
    };

    GVAR(CadStore) call ["dispatchRpcMutation", [
        _uid,
        "Invalid CAD group profile payload.",
        CRPC(cad,responseCadGroupUpdate),
        "updateGroupProfile",
        [_uid, _groupID, _status, _role],
        false,
        true
    ]];
}] call CFUNC(addEventHandler);
