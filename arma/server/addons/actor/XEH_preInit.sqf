#include "script_component.hpp"

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

[QGVAR(requestInitActor), {
    params [["_uid", "", [""]]];

    if (_uid isEqualTo "") exitWith { diag_log "[FORGE:Server:Actor] Empty/Invalid UID!" };
    GVAR(ActorStore) call ["init", [_uid]];
}] call CFUNC(addEventHandler);

[QGVAR(requestGetActor), {
    params [["_uid", "", [""]], ["_field", "", [""]]];

    if (_uid isEqualTo "") exitWith { diag_log "[FORGE:Server:Actor] Empty/Invalid UID!" };

    private _finalData = GVAR(ActorStore) call ["get", [_uid, _field]];
    private _player = [_uid] call EFUNC(common,getPlayer);

    [CRPC(actor,responseSyncActor), [_finalData], _player] call CFUNC(targetEvent);
}] call CFUNC(addEventHandler);

[QGVAR(requestSetActor), {
    params [["_uid", "", [""]], ["_field", "", [""]], ["_value", nil, [[], "", 0, false, createHashMap]], ["_sync", false, [false]]];

    if (_uid isEqualTo "" || _field isEqualTo "") exitWith { diag_log "[FORGE:Server:Actor] Empty/Invalid UID or Key!" };

    private _hashMap = GVAR(ActorStore) call ["set", [_uid, _field, _value, _sync]];
    private _player = [_uid] call EFUNC(common,getPlayer);

    [CRPC(actor,responseSyncActor), [_hashMap], _player] call CFUNC(targetEvent);
}] call CFUNC(addEventHandler);

[QGVAR(requestMSetActor), {
    params [["_uid", "", [""]], ["_fieldValuePairs", createHashMap, [createHashMap]], ["_sync", false, [false]]];

    if (_uid isEqualTo "") exitWith { diag_log "[FORGE:Server:Actor] Empty/Invalid UID!" };
    if ((_fieldValuePairs isEqualTo createHashMap) || !(_fieldValuePairs isEqualType createHashMap)) exitWith { diag_log "[FORGE:Server:Actor] Empty/Invalid field pairs!" };

    private _hashMap = GVAR(ActorStore) call ["mset", [_uid, _fieldValuePairs, _sync]];
    private _player = [_uid] call EFUNC(common,getPlayer);

    [CRPC(actor,responseSyncActor), [_hashMap], _player] call CFUNC(targetEvent);
}] call CFUNC(addEventHandler);

[QGVAR(requestSaveActor), {
    params [["_uid", "", [""]]];

    if (_uid isEqualTo "") exitWith { diag_log "[FORGE:Server:Actor] Empty/Invalid UID!" };

    GVAR(ActorStore) call ["snapshot", [_uid]];
    private _finalData = GVAR(ActorStore) call ["save", [_uid]];
    private _player = [_uid] call EFUNC(common,getPlayer);

    [CRPC(actor,responseSyncActor), [_finalData], _player] call CFUNC(targetEvent);
}] call CFUNC(addEventHandler);

[QGVAR(requestRemoveActor), {
    params [["_uid", "", [""]]];

    if (_uid isEqualTo "") exitWith { diag_log "[FORGE:Server:Actor] Empty/Invalid UID!" };
    GVAR(ActorStore) call ["remove", [_uid]];
}] call CFUNC(addEventHandler);
