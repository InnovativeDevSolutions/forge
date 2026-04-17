#include "..\script_component.hpp"

/*
 * File: fnc_openVG.sqf
 * Author: IDSolutions
 * Date: 2025-12-16
 * Last Update: 2026-04-22
 * Public: No
 *
 * Description:
 * Opens the Virtual Garage.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call forge_client_garage_fnc_openVG
 */

private _context = GVAR(GarageContextService) call ["getContext", []];
private _spawnLane = GVAR(GarageContextService) call ["getSpawnLane", [_context getOrDefault ["garageType", ""], _context]];

FORGE_VehSpawnPos = _spawnLane getOrDefault ["spawnPosition", player getPos [8, getDir player]];
missionNamespace setVariable [QGVAR(activeVGContext), _context];
missionNamespace setVariable [QGVAR(activeVGNearbyVehicles), + (FORGE_VehSpawnPos nearEntities [["Car", "Tank", "Air", "Ship"], 15])];

BIS_fnc_garage_center = createVehicle ["Land_HelipadEmpty_F", FORGE_VehSpawnPos, [], 0, "NONE"];
BIS_fnc_garage_centerType = getText (configFile >> "CfgVehicles" >> "B_Quadbike_01_F" >> "model");

if !(GVAR(isPreLoaded)) then {
    [missionNamespace, "garageOpened", {
        params ["_display", "_toggleSpace"];

        missionNamespace setVariable ["BIS_fnc_garage_data", [
            GVAR(Cars),
            GVAR(Armor),
            GVAR(Helis),
            GVAR(Planes),
            GVAR(Naval),
            GVAR(Other)
        ]];

        {
            lbClear (_display displayCtrl (960 + _forEachIndex));
        } forEach BIS_fnc_garage_data;

        _display displayAddEventHandler ["KeyDown", "_this select 3"];
        { (_display displayCtrl _x) ctrlShow false } forEach [44151, 44150, 44146, 44147, 44148, 44149, 44346, 44347, 978];

        ["ListAdd", [_display]] call BFUNC(garage);
    }] call BFUNC(addScriptedEventHandler);

    [missionNamespace, "garageClosed", {
        private _nearbyVehicles = BIS_fnc_garage_center nearEntities [["Car", "Tank", "Air", "Ship"], 15];
        private _preExistingVehicles = missionNamespace getVariable [QGVAR(activeVGNearbyVehicles), []];
        private _spawnedVehicles = _nearbyVehicles select { !(_x in _preExistingVehicles) };

        if (_spawnedVehicles isNotEqualTo []) then {
            private _spawnedVehiclePairs = _spawnedVehicles apply { [_x distance2D BIS_fnc_garage_center, _x] };
            _spawnedVehiclePairs sort true;

            private _obj = (_spawnedVehiclePairs select 0) param [1, objNull];
            if (isNull _obj) exitWith {
                missionNamespace setVariable [QGVAR(activeVGNearbyVehicles), nil];
                missionNamespace setVariable [QGVAR(activeVGContext), nil];
            };

            private _veh = typeOf _obj;
            private _textures = getObjectTextures _obj;
            private _animationNames = animationNames _obj;
            private _context = missionNamespace getVariable [QGVAR(activeVGContext), createHashMap];
            private _spawnCategory = GVAR(GarageHelperService) call ["resolveVGCategory", [_veh]];
            private _spawnLane = GVAR(GarageContextService) call ["getExactSpawnLane", [_spawnCategory, _context]];
            private _spawnLabel = GVAR(GarageHelperService) call ["resolveGarageCategoryLabel", [_spawnCategory]];

            { deleteVehicle _x } forEach _spawnedVehicles;

            if (_spawnLane isEqualTo createHashMap) exitWith {
                missionNamespace setVariable [QGVAR(activeVGNearbyVehicles), nil];
                missionNamespace setVariable [QGVAR(activeVGContext), nil];
                private _params = ["warning", "Virtual Garage", format ["This garage does not support spawning %1.", _spawnLabel], 4000];
                EGVAR(notifications,NotificationService) call ["create", _params];
            };

            private _spawnPosition = _spawnLane getOrDefault ["spawnPosition", FORGE_VehSpawnPos];
            private _spawnHeading = _spawnLane getOrDefault ["spawnHeading", getDir _obj];
            private _createVehicle = createVehicle [_veh, _spawnPosition, [], 0, "CAN_COLLIDE"];
            _createVehicle setDir _spawnHeading;

            if (_textures isNotEqualTo []) then {
                private _count = 0;
                {
                    _createVehicle setObjectTextureGlobal [_count, _x];
                    _count = _count + 1;
                } forEach _textures;
            };

            if (_animationNames isNotEqualTo []) then {
                private _animationPhase = [];

                for "_i" from 0 to count _animationNames -1 do {
                    _animationPhase pushBack [_animationNames select _i, _obj animationPhase (_animationNames select _i)];
                    { _createVehicle animate _x; } forEach _animationPhase;
                };
            };
        };

        missionNamespace setVariable [QGVAR(activeVGNearbyVehicles), nil];
        missionNamespace setVariable [QGVAR(activeVGContext), nil];
    }] call BFUNC(addScriptedEventHandler);

    GVAR(isPreLoaded) = true;
};

private _nearVehicles = FORGE_VehSpawnPos nearEntities [["Car", "Tank", "Air", "Ship"], 5];
if (_nearVehicles isNotEqualTo []) exitWith {
    private _params = ["warning", "Virtual Garage", "Vehicle spawn position is blocked. Please move the vehicle before accessing the garage.", 3000];
    EGVAR(notifications,NotificationService) call ["create", _params];
};

["Open", true] call BFUNC(garage);
