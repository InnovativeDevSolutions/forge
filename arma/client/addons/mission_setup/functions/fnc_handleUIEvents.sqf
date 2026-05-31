#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Handles JSON events from the framework mission setup browser UI.
 *
 * Arguments:
 * 0: Browser control <CONTROL>
 * 1: Whether the event came from a confirm dialog <BOOL>
 * 2: JSON event payload <STRING>
 *
 * Return Value:
 * Event handled <BOOL>
 *
 * Public: No
 */

params [
    ["_control", controlNull, [controlNull]],
    ["_isConfirmDialog", false, [false]],
    ["_message", "", [""]]
];

if (_message isEqualTo "") exitWith { false };

private _alert = fromJSON _message;
if !(_alert isEqualType createHashMap) exitWith { false };

private _event = _alert getOrDefault ["event", ""];
private _data = _alert getOrDefault ["data", createHashMap];

diag_log format ["[FORGE:Client:MissionSetup] Handling UI event: %1", _event];

private _send = {
    params ["_eventName", "_payload"];

    if (isNull _control) exitWith { false };

    private _json = toJSON createHashMapFromArray [
        ["event", _eventName],
        ["data", _payload]
    ];
    _control ctrlWebBrowserAction ["ExecJS", format ["MissionSetupBridge.receive(%1)", _json]];
    true
};

switch (_event) do {
    case "missionSetup::ready": {
        if (isNil QGVAR(MissionSetupRepository)) then { call FUNC(initRepository); };
        ["missionSetup::hydrate", GVAR(MissionSetupRepository) call ["buildSetupPayload", []]] call _send;
    };
    case "missionSetup::apply": {
        if !(_data isEqualType createHashMap) exitWith {
            ["missionSetup::error", createHashMapFromArray [["message", "Invalid mission setup payload."]]] call _send;
        };

        uiNamespace setVariable [QGVAR(MissionSetupHandled), true];
        [SRPC(task,requestApplyMissionSetupSettings), [_data, player]] call CFUNC(serverEvent);
        closeDialog 1;
    };
    case "missionSetup::cancel": {
        uiNamespace setVariable [QGVAR(MissionSetupHandled), true];
        [SRPC(task,requestApplyMissionSetupSettings), [createHashMap, player]] call CFUNC(serverEvent);
        closeDialog 1;
    };
    case "missionSetup::close": {
        uiNamespace setVariable [QGVAR(MissionSetupHandled), true];
        [SRPC(task,requestApplyMissionSetupSettings), [createHashMap, player]] call CFUNC(serverEvent);
        closeDialog 1;
    };
    default {
        ["missionSetup::error", createHashMapFromArray [["message", format ["Unhandled setup event: %1", _event]]]] call _send;
    };
};

true
