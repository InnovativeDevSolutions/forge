#include "script_component.hpp"

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

call FUNC(initCadStore);
call FUNC(registerEventListeners);

[QGVAR(requestHydrateCad), {
    params [["_uid", "", [""]]];

    private _player = GVAR(CadStore) call ["resolveRequestPlayer", [_uid, "CAD hydrate request received with empty UID."]];
    if (isNull _player) exitWith {};

    private _payload = GVAR(CadStore) call ["buildHydratePayload", [_uid]];
    [CRPC(cad,responseHydrateCad), [_payload], _player] call CFUNC(targetEvent);
}] call CFUNC(addEventHandler);

[QGVAR(requestAssignCadContract), {
    params [["_uid", "", [""]], ["_taskID", "", [""]], ["_groupID", "", [""]], ["_note", "", [""]]];

    if (_taskID isEqualTo "" || { _groupID isEqualTo "" }) exitWith {
        ["WARNING", "Invalid CAD contract assignment payload."] call EFUNC(common,log);
    };

    GVAR(CadStore) call ["handleRpc", [_uid, CRPC(cad,responseCadAssignment), "assignContract", [_uid, _taskID, _groupID, _note]]];
}] call CFUNC(addEventHandler);

[QGVAR(requestAcceptCadContract), {
    params [["_uid", "", [""]], ["_taskID", "", [""]]];

    if (_taskID isEqualTo "") exitWith {
        ["WARNING", "Invalid CAD contract accept payload."] call EFUNC(common,log);
    };

    GVAR(CadStore) call ["handleRpc", [_uid, CRPC(cad,responseCadAssignment), "acceptContract", [_uid, _taskID]]];
}] call CFUNC(addEventHandler);

[QGVAR(requestDeclineCadContract), {
    params [["_uid", "", [""]], ["_taskID", "", [""]]];

    if (_taskID isEqualTo "") exitWith {
        ["WARNING", "Invalid CAD contract decline payload."] call EFUNC(common,log);
    };

    GVAR(CadStore) call ["handleRpc", [_uid, CRPC(cad,responseCadAssignment), "declineContract", [_uid, _taskID]]];
}] call CFUNC(addEventHandler);

[QGVAR(requestUpdateCadGroupProfile), {
    params [["_uid", "", [""]], ["_groupID", "", [""]], ["_status", "", [""]], ["_role", "", [""]]];

    if (_groupID isEqualTo "") exitWith {
        ["WARNING", "Invalid CAD group profile payload."] call EFUNC(common,log);
    };

    GVAR(CadStore) call ["handleRpc", [_uid, CRPC(cad,responseCadGroupUpdate), "updateGroupProfile", [_uid, _groupID, _status, _role]]];
}] call CFUNC(addEventHandler);
