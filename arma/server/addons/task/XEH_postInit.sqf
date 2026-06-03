#include "script_component.hpp"

[SRPC(task,registerMissionGeneratorProvider), {
    params [
        ["_providerId", "", [""]],
        ["_provider", createHashMap, [createHashMap]]
    ];

    GVAR(MissionGeneratorProviderRegistry) call ["registerProvider", [_providerId, _provider]];
}] call CFUNC(addEventHandler);

[SRPC(task,registerMissionGeneratorProvider), {
    params [
        ["_providerId", "", [""]],
        ["_provider", createHashMap, [createHashMap]]
    ];

    GVAR(MissionGeneratorProviderRegistry) call ["registerProvider", [_providerId, _provider]];
}] call CFUNC(addEventHandler);

[SRPC(task,requestOpenMissionSetup), {
    params [
        ["_requester", objNull, [objNull]]
    ];

    private _notifyDenied = {
        params [
            ["_unit", objNull, [objNull]],
            ["_message", "", [""]]
        ];

        if (isNull _unit || { _message isEqualTo "" }) exitWith {};
        [CRPC(notifications,recieveNotification), ["warning", "Mission Setup", _message], _unit] call CFUNC(targetEvent);
    };

    if (isNull _requester) exitWith {
        ["WARNING", "Mission setup open request ignored: requester was null."] call EFUNC(common,log);
    };

    private _requesterVar = toLowerANSI vehicleVarName _requester;
    ["INFO", format [
        "Mission setup open requested. Requester=%1 VarName=%2 Enabled=%3 Applied=%4",
        _requester,
        _requesterVar,
        GETGVAR(enableMissionSetup,false),
        GETGVAR(missionSetup_settingsApplied,false)
    ]] call EFUNC(common,log);

    if !(GETGVAR(enableMissionSetup,false)) exitWith {
        ["INFO", "Mission setup open denied: framework mission setup is disabled."] call EFUNC(common,log);
        [_requester, "Framework mission setup is disabled for this mission."] call _notifyDenied;
    };
    if (GETGVAR(missionSetup_settingsApplied,false)) exitWith {
        ["INFO", "Mission setup open denied: settings were already applied."] call EFUNC(common,log);
        [_requester, "Mission setup has already been applied and cannot be reopened."] call _notifyDenied;
    };

    private _allowedVariables = GETGVAR(missionSetup_allowedUnitVariables,["ceo"]);
    if !(_allowedVariables isEqualType []) then { _allowedVariables = ["ceo"]; };
    _allowedVariables = _allowedVariables apply {
        if (_x isEqualType "") then { toLowerANSI _x } else { toLowerANSI str _x }
    };

    private _isSetupOperator = _requesterVar in _allowedVariables;
    if !(_isSetupOperator) then {
        {
            private _unit = missionNamespace getVariable [_x, objNull];
            if (!isNull _unit && { _requester isEqualTo _unit }) exitWith {
                _isSetupOperator = true;
            };
        } forEach _allowedVariables;
    };

    if !(_isSetupOperator) exitWith {
        ["INFO", format [
            "Mission setup open denied: requester is not an allowed setup operator. VarName=%1 Allowed=%2",
            _requesterVar,
            _allowedVariables
        ]] call EFUNC(common,log);
        [_requester, "You are not allowed to open mission setup."] call _notifyDenied;
    };

    ["INFO", format ["Mission setup open approved. Target=%1 VarName=%2", _requester, _requesterVar]] call EFUNC(common,log);
    [CRPC(mission_setup,openMissionSetup), [], _requester] call CFUNC(targetEvent);
}] call CFUNC(addEventHandler);

[SRPC(task,requestApplyMissionSetupSettings), {
    params [
        ["_overrides", createHashMap, [createHashMap]],
        ["_requester", objNull, [objNull]]
    ];

    private _allowedVariables = GETGVAR(missionSetup_allowedUnitVariables,["ceo"]);
    if !(_allowedVariables isEqualType []) then { _allowedVariables = ["ceo"]; };
    _allowedVariables = _allowedVariables apply {
        if (_x isEqualType "") then { toLowerANSI _x } else { toLowerANSI str _x }
    };

    private _requesterVar = toLowerANSI vehicleVarName _requester;
    private _isSetupOperator = _requesterVar in _allowedVariables;
    if !(_isSetupOperator) then {
        {
            private _unit = missionNamespace getVariable [_x, objNull];
            if (!isNull _unit && { _requester isEqualTo _unit }) exitWith {
                _isSetupOperator = true;
            };
        } forEach _allowedVariables;
    };

    if !(_isSetupOperator) exitWith {
        ["WARNING", format [
            "Mission setup apply request denied. Requester=%1 VarName=%2",
            _requester,
            _requesterVar
        ]] call EFUNC(common,log);
    };

    ["INFO", format ["Mission setup apply request accepted. Requester=%1 VarName=%2", _requester, _requesterVar]] call EFUNC(common,log);
    GVAR(MissionSetupService) call ["apply", [_overrides]];
}] call CFUNC(addEventHandler);

["ace_explosives_defuse", {
    private _taskID = "";
    private _explosive = objNull;
    {
        if (_x isEqualType objNull && { !isNull _x }) then {
            if (isNull _explosive) then { _explosive = _x; };
            _taskID = _x getVariable ["assignedTask", ""];
            if (_taskID isNotEqualTo "") exitWith {};
        };
    } forEach _this;

    if (_taskID isEqualTo "" && { !isNull _explosive }) then {
        _taskID = GVAR(TaskStore) call ["findTaskEntityOwner", ["ieds", _explosive]];
    };

    if (_taskID isEqualTo "") exitWith {
        ["WARNING", format [
            "ACE Defuse Event Ignored: No assignedTask found. Explosive=%1, Type=%2, NetID=%3",
            _explosive,
            typeOf _explosive,
            netId _explosive
        ]] call EFUNC(common,log);
    };

    GVAR(TaskStore) call ["incrementDefuseCount", [_taskID]];
}] call CFUNC(addEventHandler);
[] call FUNC(missionManager);
