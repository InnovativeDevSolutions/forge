#include "script_component.hpp"

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

// private _category = [QUOTE(MOD_NAME), LLSTRING(displayName)];

[QGVAR(requestInitGarage), {
    params [["_uid", "", [""]]];

    if (_uid isEqualTo "") exitWith { diag_log "[FORGE:Server:Garage] Empty/Invalid UID!" };
    GVAR(GarageStore) call ["init", [_uid]];
}] call CFUNC(addEventHandler);

[QGVAR(requestSaveGarage), {
    params [["_uid", "", [""]]];

    if (_uid isEqualTo "") exitWith { diag_log "[FORGE:Server:Garage] Empty/Invalid UID!" };

    private _finalData = GVAR(GarageStore) call ["save", [_uid]];
    private _player = [_uid] call EFUNC(common,getPlayer);

    [CRPC(garage,responseSyncGarage), [_finalData], _player] call CFUNC(targetEvent);
}] call CFUNC(addEventHandler);

[QGVAR(requestStoreVehicle), {
    params [
        ["_uid", "", [""]],
        ["_netId", "", [""]],
        ["_className", "", [""]],
        ["_fuel", 0, [0]],
        ["_damage", 0, [0]],
        ["_hitPointsJson", "", [""]]
    ];

    private _player = [_uid] call EFUNC(common,getPlayer);
    if (_uid isEqualTo "" || { _netId isEqualTo "" } || { _className isEqualTo "" } || { _hitPointsJson isEqualTo "" }) exitWith {
        [CRPC(garage,responseGarageAction), [createHashMapFromArray [
            ["action", "store"],
            ["success", false],
            ["message", "Missing vehicle data for garage storage."]
        ]], _player] call CFUNC(targetEvent);
    };

    private _payloadJson = toJSON (createHashMapFromArray [
        ["classname", _className],
        ["fuel", _fuel],
        ["damage", _damage],
        ["hit_points", fromJSON _hitPointsJson]
    ]);

    private _garage = GVAR(GarageStore) call ["storeVehicle", [_uid, _payloadJson]];
    if !(GVAR(GarageStore) call ["didLastCallSucceed", []]) exitWith {
        private _message = GVAR(GarageStore) call ["getLastError", []];
        if (_message isEqualTo "") then { _message = "Failed to store vehicle."; };
        [CRPC(garage,responseGarageAction), [createHashMapFromArray [
            ["action", "store"],
            ["success", false],
            ["message", _message]
        ]], _player] call CFUNC(targetEvent);
    };

    private _vehicle = objectFromNetId _netId;
    if !(isNull _vehicle) then {
        deleteVehicle _vehicle;
    };

    [CRPC(garage,responseSyncGarage), [_garage], _player] call CFUNC(targetEvent);
    [CRPC(garage,responseGarageAction), [createHashMapFromArray [
        ["action", "store"],
        ["success", true],
        ["message", "Vehicle stored in garage."]
    ]], _player] call CFUNC(targetEvent);
}] call CFUNC(addEventHandler);

[QGVAR(requestRetrieveVehicle), {
    params [["_uid", "", [""]], ["_plate", "", [""]]];

    private _player = [_uid] call EFUNC(common,getPlayer);
    if (_uid isEqualTo "" || { _plate isEqualTo "" }) exitWith {
        [CRPC(garage,responseGarageAction), [createHashMapFromArray [
            ["action", "retrieve"],
            ["success", false],
            ["message", "Select a stored vehicle to retrieve."]
        ]], _player] call CFUNC(targetEvent);
    };

    private _payloadJson = toJSON (createHashMapFromArray [["plate", _plate]]);
    private _garage = GVAR(GarageStore) call ["retrieveVehicle", [_uid, _payloadJson]];
    if !(GVAR(GarageStore) call ["didLastCallSucceed", []]) exitWith {
        private _message = GVAR(GarageStore) call ["getLastError", []];
        if (_message isEqualTo "") then { _message = "Failed to retrieve vehicle."; };
        [CRPC(garage,responseGarageAction), [createHashMapFromArray [
            ["action", "retrieve"],
            ["success", false],
            ["message", _message]
        ]], _player] call CFUNC(targetEvent);
    };

    [CRPC(garage,responseSyncGarage), [_garage], _player] call CFUNC(targetEvent);
    [CRPC(garage,responseGarageAction), [createHashMapFromArray [
        ["action", "retrieve"],
        ["success", true],
        ["message", "Vehicle retrieved from garage."]
    ]], _player] call CFUNC(targetEvent);
}] call CFUNC(addEventHandler);

[QGVAR(requestInitVG), {
    params [["_uid", "", [""]]];

    if (_uid isEqualTo "") exitWith { diag_log "[FORGE:Server:VGarage] Empty/Invalid UID!" };
    GVAR(VGarageStore) call ["init", [_uid]];
}] call CFUNC(addEventHandler);

[QGVAR(requestSaveVG), {
    params [["_uid", "", [""]]];

    if (_uid isEqualTo "") exitWith { diag_log "[FORGE:Server:VGarage] Empty/Invalid UID!" };

    private _finalData = GVAR(VGarageStore) call ["save", [_uid]];
    private _player = [_uid] call EFUNC(common,getPlayer);

    [CRPC(garage,responseSyncVG), [_finalData], _player] call CFUNC(targetEvent);
}] call CFUNC(addEventHandler);

