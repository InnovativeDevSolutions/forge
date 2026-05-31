[
    QGVAR(enableGenerator), "CHECKBOX",
    [LSTRING(enableGenerator), LSTRING(enableGeneratorTooltip)],
    _category, false, true
] call CBA_fnc_addSetting;

[
    QGVAR(enableMissionSetup), "CHECKBOX",
    [LSTRING(enableMissionSetup), LSTRING(enableMissionSetupTooltip)],
    _category, false, true
] call CBA_fnc_addSetting;

[
    QGVAR(enableEventLogs), "CHECKBOX",
    [LSTRING(enableEventLogs), LSTRING(enableEventLogsTooltip)],
    _category, false, true
] call CBA_fnc_addSetting;
