#include "..\script_component.hpp"

/*
 * File: fnc_initGarage.sqf
 * Author: IDSolutions
 * Date: 2025-12-17
 * Last Update: 2026-02-05
 * Public: No
 *
 * Description:
 * Initializes all editor-placed garages.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call forge_server_garage_fnc_initGarage
 */

private _resolveGarageType = {
    params [["_value", "", [""]]];

    private _normalized = toLowerANSI (trim _value);

    switch (true) do {
        case ((_normalized find "cars") >= 0): { "cars" };
        case ((_normalized find "armor") >= 0): { "armor" };
        case ((_normalized find "helis") >= 0): { "helis" };
        case ((_normalized find "planes") >= 0): { "planes" };
        case ((_normalized find "naval") >= 0): { "naval" };
        case ((_normalized find "other") >= 0): { "other" };
        default { "" };
    }
};

private _garages = (allVariables missionNamespace) select {
    private _var = missionNamespace getVariable _x;
    ((toLowerANSI _x) find "garage") >= 0 && { _var isEqualType objNull } && { !isNull _var }
};

if (_garages isEqualTo []) exitWith { ["INFO", "No editor-placed garages found."] call EFUNC(common,log) };

{
    private _garageName = _x;
    private _garage = missionNamespace getVariable _garageName;
    SETPVAR(_garage,isGarage,true);
    if ((_garage getVariable ["garageType", ""]) isEqualTo "") then {
        private _garageType = _garageName call _resolveGarageType;
        if (_garageType isNotEqualTo "") then {
            SETPVAR(_garage,garageType,_garageType);
        };
    };
} forEach _garages;
