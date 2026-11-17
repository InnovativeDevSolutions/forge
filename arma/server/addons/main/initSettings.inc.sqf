[
    QGVAR(autosaveInterval), "SLIDER",
    [LSTRING(autosaveInterval), LSTRING(autosaveIntervalTooltip)],
    _category, [0, 60, 5, 0], 1
] call CBA_fnc_addSetting;

[
    QGVAR(flushTimeout), "SLIDER",
    [LSTRING(flushTimeout), LSTRING(flushTimeoutTooltip)],
    _category, [1000, 30000, 10000, 0], 1
] call CBA_fnc_addSetting;
