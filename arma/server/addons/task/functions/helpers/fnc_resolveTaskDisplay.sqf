#include "..\script_component.hpp"

/*
 * File: fnc_resolveTaskDisplay.sqf
 * Author: IDSolutions
 * Date: 2026-05-28
 * Public: No
 *
 * Description:
 * Resolves task title and description for framework task modules. If a vanilla
 * task with the same ID already exists, its BIS task framework description is
 * preferred so Eden Create Task metadata is preserved in CAD.
 *
 * Arguments:
 * 0: Task ID <STRING>
 * 1: Fallback title <STRING>
 * 2: Fallback description <STRING>
 *
 * Return Value:
 * [title, description] <ARRAY>
 *
 * Example:
 * ["task_1", "Attack: task_1", "Eliminate all hostile forces."] call forge_server_task_fnc_resolveTaskDisplay
 */

params [
    ["_taskID", "", [""]],
    ["_fallbackTitle", "", [""]],
    ["_fallbackDescription", "", [""]]
];

private _title = _fallbackTitle;
private _description = _fallbackDescription;
private _resolveTextValue = {
    params ["_value"];

    if (_value isEqualType "") exitWith { _value };
    if (_value isEqualType [] && { count _value > 0 }) exitWith {
        private _firstValue = _value select 0;
        if (_firstValue isEqualType "") exitWith { _firstValue };
        ""
    };

    ""
};

if (_taskID isEqualTo "") exitWith { [_title, _description] };

private _taskExists = [_taskID] call BFUNC(taskExists);

if (_taskExists) then {
    private _taskDescription = _taskID call BFUNC(taskDescription);

    if (_taskDescription isEqualType [] && { count _taskDescription >= 2 }) then {
        private _descriptionValue = _taskDescription select 0;
        private _titleValue = _taskDescription select 1;
        private _resolvedTitleValue = [_titleValue] call _resolveTextValue;
        private _resolvedDescriptionValue = [_descriptionValue] call _resolveTextValue;

        if (_resolvedTitleValue isNotEqualTo "") then { _title = _resolvedTitleValue; };
        if (_resolvedDescriptionValue isNotEqualTo "") then { _description = _resolvedDescriptionValue; };
    };
};

[_title, _description]
