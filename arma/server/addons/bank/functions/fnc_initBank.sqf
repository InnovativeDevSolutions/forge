#include "..\script_component.hpp"

/*
 * File: fnc_initBank.sqf
 * Author: IDSolutions
 * Date: 2025-12-17
 * Last Update: 2026-02-17
 * Public: No
 *
 * Description:
 * Initializes all editor-placed banks.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call forge_server_bank_fnc_initBank
 */

private _atms = (allVariables missionNamespace) select {
    private _var = missionNamespace getVariable _x;
    ("atm" in _x) && { _var isEqualType objNull } && { !isNull _var }
};

private _banks = (allVariables missionNamespace) select {
    private _var = missionNamespace getVariable _x;
    ("bank" in _x) && { _var isEqualType objNull } && { !isNull _var }
};

if (_atms isNotEqualTo []) then {
    {
        private _atm = missionNamespace getVariable _x;
        SETPVAR(_atm,isAtm,true);
    } forEach _atms;
} else {
    ["INFO", "No editor-placed atms found."] call EFUNC(common,log);
};

if (_banks isNotEqualTo []) then {
    {
        private _bank = missionNamespace getVariable _x;
        SETPVAR(_bank,isBank,true);
    } forEach _banks;
} else {
    ["INFO", "No editor-placed banks found."] call EFUNC(common,log);
};
