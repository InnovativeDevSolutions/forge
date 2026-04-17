#include "script_component.hpp"

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

// private _category = [QUOTE(MOD_NAME), LLSTRING(displayName)];

[QGVAR(requestInitLocker), {
    params [["_uid", "", [""]]];

    if (_uid isEqualTo "") exitWith { diag_log "[FORGE:Server:Locker] Empty/Invalid UID!" };
    GVAR(LockerStore) call ["init", [_uid]];
}] call CFUNC(addEventHandler);

[QGVAR(requestSaveLocker), {
    params [["_uid", "", [""]]];

    if (_uid isEqualTo "") exitWith { diag_log "[FORGE:Server:Locker] Empty/Invalid UID!" };

    private _finalData = GVAR(LockerStore) call ["save", [_uid]];
    private _player = [_uid] call EFUNC(common,getPlayer);

    [CRPC(locker,responseSyncLocker), [_finalData], _player] call CFUNC(targetEvent);
}] call CFUNC(addEventHandler);

[QGVAR(requestOverrideLocker), {
    params [["_uid", "", [""]], ["_data", createHashMap, [createHashMap]]];

    if (_uid isEqualTo "") exitWith { diag_log "[FORGE:Server:Locker] Empty/Invalid UID!" };
    private _finalData = GVAR(LockerStore) call ["override", [_uid, _data, false]];

    private _player = [_uid] call EFUNC(common,getPlayer);
    [CRPC(locker,responseSyncLocker), [_finalData], _player] call CFUNC(targetEvent);
}] call CFUNC(addEventHandler);

[QGVAR(requestInitVA), {
    params [["_uid", "", [""]]];

    if (_uid isEqualTo "") exitWith { diag_log "[FORGE:Server:VArsenal] Empty/Invalid UID!" };
    GVAR(VAStore) call ["init", [_uid]];
}] call CFUNC(addEventHandler);

[QGVAR(requestSaveVA), {
    params [["_uid", "", [""]]];

    if (_uid isEqualTo "") exitWith { diag_log "[FORGE:Server:VArsenal] Empty/Invalid UID!" };

    private _finalData = GVAR(VAStore) call ["save", [_uid]];
    private _player = [_uid] call EFUNC(common,getPlayer);

    [CRPC(locker,responseSyncVA), [_finalData], _player] call CFUNC(targetEvent);
}] call CFUNC(addEventHandler);

