// Can use localize "STR_ACE_Common_Enabled" for name if ACE is required
[
    QGVAR(enableLoc), "CHECKBOX",
    [LSTRING(enableLoc), LSTRING(enableLocTooltip)],
    _category, true, true
] call CBA_fnc_addSetting;

[
    QGVAR(enableGear), "CHECKBOX",
    [LSTRING(enableGear), LSTRING(enableGearTooltip)],
    _category, true, true
] call CBA_fnc_addSetting;

[
    QGVAR(enableVA), "CHECKBOX",
    [LSTRING(enableVA), LSTRING(enableVATooltip)],
    _category, true, true
] call CBA_fnc_addSetting;

[
    QGVAR(enableVG), "CHECKBOX",
    [LSTRING(enableVG), LSTRING(enableVGTooltip)],
    _category, true, true
] call CBA_fnc_addSetting;
