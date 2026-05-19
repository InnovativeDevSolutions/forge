#include "..\script_component.hpp"

/*
 * File: fnc_handleUIEvents.sqf
 * Author: IDSolutions
 * Date: 2026-03-28
 * Public: No
 *
 * Description:
 * Handles CAD browser UI events.
 *
 * Arguments:
 * 0: Control [CONTROL]
 * 1: Confirm dialog flag [BOOL]
 * 2: Browser message [STRING]
 *
 * Return Value:
 * UI event handled [BOOL]
 *
 * Example:
 * [_control, false, _message] call forge_client_cad_fnc_handleUIEvents
 */

params ["_control", "_isConfirmDialog", "_message"];

private _alert = fromJSON _message;
private _event = _alert getOrDefault ["event", ""];
private _data = _alert getOrDefault ["data", nil];

diag_log format ["[FORGE:Client:CAD] Handling UI event: %1", _event];

if (_isConfirmDialog) exitWith { true };

switch (_event) do {
    case "cad::topbar::ready": {
        GVAR(CADUIBridge) call ["handleTopBarReady", []];
    };
    case "cad::ready": {
        GVAR(CADUIBridge) call ["handleReady", [_control, _data]];
    };
    case "cad::dispatcher::ready": {
        GVAR(CADUIBridge) call ["handleDispatcherReady", []];
    };
    case "cad::mode::set": {
        private _mode = "";
        if (_data isEqualType createHashMap) then {
            _mode = _data getOrDefault ["mode", ""];
        };

        GVAR(CADUIBridge) call ["setMode", [_mode]];
    };
    case "cad::dispatchView::set": {
        private _dispatchView = "";
        if (_data isEqualType createHashMap) then {
            _dispatchView = _data getOrDefault ["dispatchView", ""];
        };

        GVAR(CADUIBridge) call ["setDispatchView", [_dispatchView]];
    };
    case "cad::refresh": {
        GVAR(CADUIBridge) call ["requestHydrate", []];
    };
    case "cad::tasks::assign": {
        private _taskID = "";
        private _groupID = "";
        private _note = "";
        if (_data isEqualType createHashMap) then {
            _taskID = _data getOrDefault ["taskID", ""];
            _groupID = _data getOrDefault ["groupID", ""];
            _note = _data getOrDefault ["note", ""];
        };

        GVAR(CADUIBridge) call ["requestAssignTask", [_taskID, _groupID, _note]];
    };
    case "cad::dispatchOrder::create": {
        private _assigneeGroupID = "";
        private _targetGroupID = "";
        private _note = "";
        private _priority = "priority";
        private _request = createHashMap;
        if (_data isEqualType createHashMap) then {
            _assigneeGroupID = _data getOrDefault ["assigneeGroupID", ""];
            _targetGroupID = _data getOrDefault ["targetGroupID", ""];
            _note = _data getOrDefault ["note", ""];
            _priority = _data getOrDefault ["priority", "priority"];
            _request = _data getOrDefault ["request", createHashMap];
        };

        GVAR(CADUIBridge) call ["requestCreateDispatchOrder", [_assigneeGroupID, _targetGroupID, _note, _priority, _request]];
    };
    case "cad::supportRequest::submit": {
        private _type = "";
        private _fields = createHashMap;
        private _priority = "priority";
        if (_data isEqualType createHashMap) then {
            _type = _data getOrDefault ["type", ""];
            _fields = _data getOrDefault ["fields", createHashMap];
            _priority = _data getOrDefault ["priority", "priority"];
        };

        GVAR(CADUIBridge) call ["requestSubmitSupportRequest", [_type, _fields, _priority]];
    };
    case "cad::dispatchOrder::close": {
        private _taskID = "";
        if (_data isEqualType createHashMap) then {
            _taskID = _data getOrDefault ["taskID", ""];
        };

        GVAR(CADUIBridge) call ["requestCloseDispatchOrder", [_taskID]];
    };
    case "cad::supportRequest::close": {
        private _requestID = "";
        if (_data isEqualType createHashMap) then {
            _requestID = _data getOrDefault ["requestID", ""];
        };

        GVAR(CADUIBridge) call ["requestCloseSupportRequest", [_requestID]];
    };
    case "cad::tasks::acknowledge": {
        private _taskID = "";
        if (_data isEqualType createHashMap) then {
            _taskID = _data getOrDefault ["taskID", ""];
        };

        GVAR(CADUIBridge) call ["requestAcknowledgeTask", [_taskID]];
    };
    case "cad::tasks::decline": {
        private _taskID = "";
        if (_data isEqualType createHashMap) then {
            _taskID = _data getOrDefault ["taskID", ""];
        };

        GVAR(CADUIBridge) call ["requestDeclineTask", [_taskID]];
    };
    case "cad::groups::status": {
        private _groupID = "";
        private _status = "";
        if (_data isEqualType createHashMap) then {
            _groupID = _data getOrDefault ["groupID", ""];
            _status = _data getOrDefault ["status", ""];
        };

        GVAR(CADUIBridge) call ["requestGroupStatus", [_groupID, _status]];
    };
    case "cad::groups::role": {
        private _groupID = "";
        private _role = "";
        if (_data isEqualType createHashMap) then {
            _groupID = _data getOrDefault ["groupID", ""];
            _role = _data getOrDefault ["role", ""];
        };

        GVAR(CADUIBridge) call ["requestGroupRole", [_groupID, _role]];
    };
    case "cad::groups::profile": {
        private _groupID = "";
        private _status = "";
        private _role = "";
        if (_data isEqualType createHashMap) then {
            _groupID = _data getOrDefault ["groupID", ""];
            _status = _data getOrDefault ["status", ""];
            _role = _data getOrDefault ["role", ""];
        };

        GVAR(CADUIBridge) call ["requestGroupProfile", [_groupID, _status, _role]];
    };
    case "cad::groups::focus": {
        private _groupID = "";
        if (_data isEqualType createHashMap) then {
            _groupID = _data getOrDefault ["groupID", ""];
        };

        GVAR(CADUIBridge) call ["focusGroup", [_groupID]];
    };
    case "cad::members::focus": {
        private _uid = "";
        if (_data isEqualType createHashMap) then {
            _uid = _data getOrDefault ["uid", ""];
        };

        GVAR(CADUIBridge) call ["focusMember", [_uid]];
    };
    case "cad::tasks::focus": {
        private _taskID = "";
        if (_data isEqualType createHashMap) then {
            _taskID = _data getOrDefault ["taskID", ""];
        };

        GVAR(CADUIBridge) call ["focusTask", [_taskID]];
    };
    case "cad::requests::focus": {
        private _requestID = "";
        if (_data isEqualType createHashMap) then {
            _requestID = _data getOrDefault ["requestID", ""];
        };

        GVAR(CADUIBridge) call ["focusRequest", [_requestID]];
    };
    case "map::zoomIn": {
        private _mapCtrl = uiNamespace getVariable [QGVAR(MapCtrl), controlNull];
        if (isNull _mapCtrl) exitWith {};

        private _currentZoom = ctrlMapScale _mapCtrl;
        private _newZoom = (_currentZoom * 0.5) max 0.001;
        private _center = _mapCtrl ctrlMapScreenToWorld [0.5, 0.5];
        _mapCtrl ctrlMapAnimAdd [0.3, _newZoom, _center];
        ctrlMapAnimCommit _mapCtrl;
    };
    case "map::zoomOut": {
        private _mapCtrl = uiNamespace getVariable [QGVAR(MapCtrl), controlNull];
        if (isNull _mapCtrl) exitWith {};

        private _currentZoom = ctrlMapScale _mapCtrl;
        private _newZoom = (_currentZoom * 2) min 1;
        private _center = _mapCtrl ctrlMapScreenToWorld [0.5, 0.5];
        _mapCtrl ctrlMapAnimAdd [0.3, _newZoom, _center];
        ctrlMapAnimCommit _mapCtrl;
    };
    case "map::search": {
        private _query = str _data;
        private _bottomBar = uiNamespace getVariable [QGVAR(BottomBarCtrl), controlNull];
        if (isNull _bottomBar) exitWith {};

        _bottomBar ctrlWebBrowserAction ["ExecJS", format ["updateStatus('Search not yet implemented: %1');", _query]];
    };
    case "map::close": {
        if !(isNil QGVAR(CADUIBridge)) then {
            GVAR(CADUIBridge) call ["handleClose", []];
        };
        closeDialog 1;
    };
    default {
        diag_log format ["[FORGE:Client:CAD] WARNING: Unhandled UI event: %1", _event];
    };
};

true
