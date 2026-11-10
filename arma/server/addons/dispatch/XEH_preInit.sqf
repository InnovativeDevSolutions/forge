#include "script_component.hpp"

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

call FUNC(initDispatchStore);
call FUNC(registerEventListeners);

// Responses reuse the CAD client RPCs so the CAD UI needs no extra handlers.

[QGVAR(requestCreateOrder), {
    params [
        ["_uid", "", [""]],
        ["_assigneeGroupID", "", [""]],
        ["_targetGroupID", "", [""]],
        ["_note", "", [""]],
        ["_priority", "priority", [""]],
        ["_request", createHashMap, [createHashMap]]
    ];

    if (_assigneeGroupID isEqualTo "" || { _targetGroupID isEqualTo "" }) exitWith {
        ["WARNING", "Invalid dispatch order payload."] call EFUNC(common,log);
    };

    GVAR(DispatchStore) call ["handleRpc", [_uid, CRPC(cad,responseCadAssignment), "createOrder", [_uid, _assigneeGroupID, _targetGroupID, _note, _priority, _request]]];
}] call CFUNC(addEventHandler);

[QGVAR(requestCloseOrder), {
    params [["_uid", "", [""]], ["_taskID", "", [""]]];

    if (_taskID isEqualTo "") exitWith {
        ["WARNING", "Invalid dispatch order close payload."] call EFUNC(common,log);
    };

    GVAR(DispatchStore) call ["handleRpc", [_uid, CRPC(cad,responseCadAssignment), "closeOrder", [_uid, _taskID]]];
}] call CFUNC(addEventHandler);

[QGVAR(requestSubmitSupportRequest), {
    params [
        ["_uid", "", [""]],
        ["_type", "", [""]],
        ["_fields", createHashMap, [createHashMap]],
        ["_priority", "priority", [""]]
    ];

    if (_type isEqualTo "") exitWith {
        ["WARNING", "Invalid support request payload."] call EFUNC(common,log);
    };

    GVAR(DispatchStore) call ["handleRpc", [_uid, CRPC(cad,responseCadRequest), "submitRequest", [_uid, _type, _fields, _priority]]];
}] call CFUNC(addEventHandler);

[QGVAR(requestCloseSupportRequest), {
    params [["_uid", "", [""]], ["_requestID", "", [""]]];

    if (_requestID isEqualTo "") exitWith {
        ["WARNING", "Invalid support request close payload."] call EFUNC(common,log);
    };

    GVAR(DispatchStore) call ["handleRpc", [_uid, CRPC(cad,responseCadRequest), "closeRequest", [_uid, _requestID]]];
}] call CFUNC(addEventHandler);

[QGVAR(requestGeneratedMission), {
    params [["_uid", "", [""]], ["_taskType", "", [""]], ["_metadata", createHashMap, [createHashMap]]];

    GVAR(DispatchStore) call ["handleRpc", [_uid, CRPC(cad,responseCadRequest), "requestGeneratedMission", [_uid, _taskType, _metadata]]];
}] call CFUNC(addEventHandler);
