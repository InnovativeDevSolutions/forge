#include "..\script_component.hpp"

/*
 * File: fnc_initUIBridge.sqf
 * Author: IDSolutions
 * Date: 2026-03-28
 * Public: No
 *
 * Description:
 * Initializes the CAD UI bridge for sidepanel browser state and CAD event routing.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * CAD UI bridge object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_client_cad_fnc_initUIBridge
 */

#pragma hemtt ignore_variables ["_self"]
private _webUIDeclarations = call EFUNC(common,initWebUIBridge);
private _webUIBridgeDeclaration = _webUIDeclarations get "bridgeDeclaration";

GVAR(CADUIBridgeBaseClass) = compileFinal createHashMapFromArray [
    ["#base", _webUIBridgeDeclaration],
    ["#type", "CADUIBridgeBaseClass"],
    ["#create", compileFinal {
        _self set ["dispatcherReady", false];
        _self set ["topBarReady", false];
    }],
    ["getActiveBrowserControl", compileFinal {
        private _display = uiNamespace getVariable [QGVAR(Display), displayNull];
        if (isNull _display) exitWith {
            _self call ["setActiveBrowserControl", [controlNull]];
            controlNull
        };

        private _control = _display displayCtrl 1005;
        _self call ["setActiveBrowserControl", [_control]];
        _control
    }],
    ["getTopBarControl", compileFinal {
        private _display = uiNamespace getVariable [QGVAR(Display), displayNull];
        if (isNull _display) exitWith { controlNull };

        _display displayCtrl 1002
    }],
    ["getBottomBarControl", compileFinal {
        private _display = uiNamespace getVariable [QGVAR(Display), displayNull];
        if (isNull _display) exitWith { controlNull };

        _display displayCtrl 1003
    }],
    ["getMapControl", compileFinal {
        private _display = uiNamespace getVariable [QGVAR(Display), displayNull];
        if (isNull _display) exitWith { controlNull };

        _display displayCtrl 1001
    }],
    ["getDispatcherControl", compileFinal {
        private _display = uiNamespace getVariable [QGVAR(Display), displayNull];
        if (isNull _display) exitWith { controlNull };

        _display displayCtrl 1006
    }],
    ["hasOpenScreen", compileFinal {
        private _screen = _self call ["getScreen", []];
        private _control = _self call ["getActiveBrowserControl", []];
        !(isNull _control) && { _screen call ["isReady", []] }
    }],
    ["isDispatcher", compileFinal {
        if (isNil QGVAR(CADRepository)) exitWith { false };

        private _session = GVAR(CADRepository) getOrDefault ["session", createHashMap];
        _session getOrDefault ["isDispatcher", false]
    }],
    ["applyLayout", compileFinal {
        private _mode = if (isNil QGVAR(CADRepository)) then {
            "operations"
        } else {
            GVAR(CADRepository) getOrDefault ["mode", "operations"]
        };
        private _dispatchView = if (isNil QGVAR(CADRepository)) then {
            "board"
        } else {
            GVAR(CADRepository) getOrDefault ["dispatchView", "board"]
        };

        private _mapCtrl = _self call ["getMapControl", []];
        private _bottomBarCtrl = _self call ["getBottomBarControl", []];
        private _sidePanelCtrl = _self call ["getActiveBrowserControl", []];
        private _dispatcherCtrl = _self call ["getDispatcherControl", []];

        private _showMapLayout = (_mode isEqualTo "operations") || { _mode isEqualTo "dispatch" && { _dispatchView isEqualTo "map" } };

        if !(isNull _mapCtrl) then { _mapCtrl ctrlShow _showMapLayout; };
        if !(isNull _bottomBarCtrl) then { _bottomBarCtrl ctrlShow true; };
        if !(isNull _sidePanelCtrl) then { _sidePanelCtrl ctrlShow _showMapLayout; };
        if !(isNull _dispatcherCtrl) then { _dispatcherCtrl ctrlShow (_mode isEqualTo "dispatch" && { _dispatchView isEqualTo "board" }); };

        _self call ["refreshHydrate", []];
        _self call ["refreshTopBarState", []];
        _self call ["refreshDispatcher", []];
        true
    }],
    ["setMode", compileFinal {
        params [["_mode", "operations", [""]]];

        if (isNil QGVAR(CADRepository)) exitWith { false };

        private _targetMode = _mode;
        if !(_targetMode in ["operations", "dispatch"]) then {
            _targetMode = "operations";
        };

        if (_targetMode isEqualTo "dispatch" && !(_self call ["isDispatcher", []])) then {
            _targetMode = "operations";
        };

        GVAR(CADRepository) call ["setMode", [_targetMode]];
        if (_targetMode isEqualTo "dispatch") then {
            GVAR(CADRepository) call ["setDispatchView", ["board"]];
        };
        _self call ["applyLayout", []]
    }],
    ["setDispatchView", compileFinal {
        params [["_dispatchView", "board", [""]]];

        if (isNil QGVAR(CADRepository)) exitWith { false };
        if ((GVAR(CADRepository) getOrDefault ["mode", "operations"]) isNotEqualTo "dispatch") exitWith { false };
        if !(_self call ["isDispatcher", []]) exitWith { false };

        GVAR(CADRepository) call ["setDispatchView", [_dispatchView]];
        _self call ["applyLayout", []]
    }],
    ["refreshTopBarState", compileFinal {
        if !(_self getOrDefault ["topBarReady", false]) exitWith { false };

        if (isNil QGVAR(CADRepository)) exitWith { false };

        private _topBarCtrl = _self call ["getTopBarControl", []];
        if (isNull _topBarCtrl) exitWith { false };

        private _session = +(GVAR(CADRepository) getOrDefault ["session", createHashMap]);
        private _currentGroup = GVAR(CADRepository) call ["getCurrentGroup", []];
        private _payload = createHashMapFromArray [
            ["mode", GVAR(CADRepository) getOrDefault ["mode", "operations"]],
            ["dispatchView", GVAR(CADRepository) getOrDefault ["dispatchView", "board"]],
            ["session", _session],
            ["currentGroup", _currentGroup]
        ];

        _topBarCtrl ctrlWebBrowserAction ["ExecJS", format [
            "window.cadTopbar && window.cadTopbar.receiveState(%1);",
            toJSON _payload
        ]];
        true
    }],
    ["refreshDispatcher", compileFinal {
        if !(_self getOrDefault ["dispatcherReady", false]) exitWith { false };
        if (isNil QGVAR(CADRepository)) exitWith { false };

        private _dispatcherCtrl = _self call ["getDispatcherControl", []];
        if (isNull _dispatcherCtrl) exitWith { false };

        private _payload = GVAR(CADRepository) call ["getHydratePayload", []];
        _dispatcherCtrl ctrlWebBrowserAction ["ExecJS", format [
            "window.cadDispatcher && window.cadDispatcher.receiveHydrate(%1);",
            toJSON _payload
        ]];
        true
    }],
    ["handleReady", compileFinal {
        params [["_control", controlNull, [controlNull]], ["_data", createHashMap, [createHashMap]]];

        private _screen = _self call ["getScreen", []];
        _screen call ["setControl", [_control]];
        _screen call ["markReady", [true]];
        _self call ["flushPendingEvents", []];

        _self call ["requestHydrate", []];
        _self call ["refreshHydrate", []];
        _self call ["refreshTopBarState", []];
        true
    }],
    ["handleClose", compileFinal {
        _self set ["dispatcherReady", false];
        _self set ["topBarReady", false];

        private _screen = _self call ["getScreen", []];
        _screen call ["dispose", []];
        true
    }],
    ["handleTopBarReady", compileFinal {
        _self set ["topBarReady", true];
        _self call ["refreshTopBarState", []]
    }],
    ["handleDispatcherReady", compileFinal {
        _self set ["dispatcherReady", true];
        _self call ["refreshDispatcher", []]
    }],
    ["requestHydrate", compileFinal {
        [SRPC(cad,requestHydrateCad), [getPlayerUID player]] call CFUNC(serverEvent);
        true
    }],
    ["requestAssignTask", compileFinal {
        params [["_taskID", "", [""]], ["_groupID", "", [""]], ["_note", "", [""]]];

        if (_taskID isEqualTo "" || { _groupID isEqualTo "" }) exitWith { false };

        [SRPC(cad,requestAssignCadTask), [getPlayerUID player, _taskID, _groupID, _note]] call CFUNC(serverEvent);
        true
    }],
    ["requestCreateDispatchOrder", compileFinal {
        params [
            ["_assigneeGroupID", "", [""]],
            ["_targetGroupID", "", [""]],
            ["_note", "", [""]],
            ["_priority", "priority", [""]],
            ["_request", createHashMap, [createHashMap]]
        ];

        if (_assigneeGroupID isEqualTo "" || { _targetGroupID isEqualTo "" }) exitWith { false };

        [SRPC(cad,requestCreateCadDispatchOrder), [getPlayerUID player, _assigneeGroupID, _targetGroupID, _note, _priority, _request]] call CFUNC(serverEvent);
        true
    }],
    ["requestSubmitSupportRequest", compileFinal {
        params [
            ["_type", "", [""]],
            ["_fields", createHashMap, [createHashMap]],
            ["_priority", "priority", [""]]
        ];

        if (_type isEqualTo "") exitWith { false };

        [SRPC(cad,requestSubmitCadSupportRequest), [getPlayerUID player, _type, _fields, _priority]] call CFUNC(serverEvent);
        true
    }],
    ["requestCloseDispatchOrder", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { false };

        [SRPC(cad,requestCloseCadDispatchOrder), [getPlayerUID player, _taskID]] call CFUNC(serverEvent);
        true
    }],
    ["requestCloseSupportRequest", compileFinal {
        params [["_requestID", "", [""]]];

        if (_requestID isEqualTo "") exitWith { false };

        [SRPC(cad,requestCloseCadSupportRequest), [getPlayerUID player, _requestID]] call CFUNC(serverEvent);
        true
    }],
    ["requestAcknowledgeTask", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { false };

        [SRPC(cad,requestAcknowledgeCadTask), [getPlayerUID player, _taskID]] call CFUNC(serverEvent);
        true
    }],
    ["requestDeclineTask", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { false };

        [SRPC(cad,requestDeclineCadTask), [getPlayerUID player, _taskID]] call CFUNC(serverEvent);
        true
    }],
    ["requestGroupStatus", compileFinal {
        params [["_groupID", "", [""]], ["_status", "", [""]]];

        if (_groupID isEqualTo "" || { _status isEqualTo "" }) exitWith { false };

        [SRPC(cad,requestUpdateCadGroupStatus), [getPlayerUID player, _groupID, _status]] call CFUNC(serverEvent);
        true
    }],
    ["requestGroupRole", compileFinal {
        params [["_groupID", "", [""]], ["_role", "", [""]]];

        if (_groupID isEqualTo "" || { _role isEqualTo "" }) exitWith { false };

        [SRPC(cad,requestUpdateCadGroupRole), [getPlayerUID player, _groupID, _role]] call CFUNC(serverEvent);
        true
    }],
    ["requestGroupProfile", compileFinal {
        params [["_groupID", "", [""]], ["_status", "", [""]], ["_role", "", [""]]];

        if (_groupID isEqualTo "") exitWith { false };
        if (_status isEqualTo "" && { _role isEqualTo "" }) exitWith { false };

        [SRPC(cad,requestUpdateCadGroupProfile), [getPlayerUID player, _groupID, _status, _role]] call CFUNC(serverEvent);
        true
    }],
    ["focusGroup", compileFinal {
        params [["_groupID", "", [""]]];

        if (_groupID isEqualTo "") exitWith { false };
        if (isNil QGVAR(CADRepository)) exitWith { false };

        private _groups = GVAR(CADRepository) getOrDefault ["groups", []];
        private _groupIndex = _groups findIf { (_x getOrDefault ["groupId", ""]) isEqualTo _groupID };
        if (_groupIndex < 0) exitWith { false };

        private _group = _groups # _groupIndex;
        private _position = _group getOrDefault ["position", []];
        if !(_position isEqualType []) exitWith { false };
        if ((count _position) < 2) exitWith { false };

        private _mapCtrl = _self call ["getMapControl", []];
        if (isNull _mapCtrl) exitWith { false };

        private _targetPosition = [_position # 0, _position # 1, 0];
        _mapCtrl ctrlMapAnimAdd [0.35, ctrlMapScale _mapCtrl, _targetPosition];
        ctrlMapAnimCommit _mapCtrl;
        true
    }],
    ["focusMember", compileFinal {
        params [["_uid", "", [""]]];

        if (_uid isEqualTo "") exitWith { false };
        if (isNil QGVAR(CADRepository)) exitWith { false };

        private _groups = GVAR(CADRepository) getOrDefault ["groups", []];
        private _position = [];
        {
            private _members = _x getOrDefault ["members", []];
            private _memberIndex = _members findIf { (_x getOrDefault ["uid", ""]) isEqualTo _uid };
            if (_memberIndex >= 0) exitWith {
                _position = (_members # _memberIndex) getOrDefault ["position", []];
            };
        } forEach _groups;

        if !(_position isEqualType []) exitWith { false };
        if ((count _position) < 2) exitWith { false };

        private _mapCtrl = _self call ["getMapControl", []];
        if (isNull _mapCtrl) exitWith { false };

        private _targetPosition = [_position # 0, _position # 1, 0];
        _mapCtrl ctrlMapAnimAdd [0.35, ctrlMapScale _mapCtrl, _targetPosition];
        ctrlMapAnimCommit _mapCtrl;
        true
    }],
    ["focusTask", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { false };
        if (isNil QGVAR(CADRepository)) exitWith { false };

        private _contracts = GVAR(CADRepository) getOrDefault ["contracts", []];
        private _taskIndex = _contracts findIf {
            private _entryTaskID = _x getOrDefault ["taskId", _x getOrDefault ["taskID", ""]];
            _entryTaskID isEqualTo _taskID
        };
        if (_taskIndex < 0) exitWith { false };

        private _task = _contracts # _taskIndex;
        private _position = _task getOrDefault ["position", []];
        if !(_position isEqualType []) exitWith { false };
        if ((count _position) < 2) exitWith { false };

        private _mapCtrl = _self call ["getMapControl", []];
        if (isNull _mapCtrl) exitWith { false };

        private _targetPosition = [_position # 0, _position # 1, 0];
        _mapCtrl ctrlMapAnimAdd [0.35, ctrlMapScale _mapCtrl, _targetPosition];
        ctrlMapAnimCommit _mapCtrl;
        true
    }],
    ["focusRequest", compileFinal {
        params [["_requestID", "", [""]]];

        if (_requestID isEqualTo "") exitWith { false };
        if (isNil QGVAR(CADRepository)) exitWith { false };

        private _requests = GVAR(CADRepository) getOrDefault ["requests", []];
        private _requestIndex = _requests findIf { (_x getOrDefault ["requestId", ""]) isEqualTo _requestID };
        if (_requestIndex < 0) exitWith { false };

        private _request = _requests # _requestIndex;
        private _position = _request getOrDefault ["position", []];
        if !(_position isEqualType []) exitWith { false };
        if ((count _position) < 2) exitWith { false };

        private _mapCtrl = _self call ["getMapControl", []];
        if (isNull _mapCtrl) exitWith { false };

        private _targetPosition = [_position # 0, _position # 1, 0];
        _mapCtrl ctrlMapAnimAdd [0.35, ctrlMapScale _mapCtrl, _targetPosition];
        ctrlMapAnimCommit _mapCtrl;
        true
    }],
    ["refreshHydrate", compileFinal {
        if (isNil QGVAR(CADRepository)) exitWith { false };
        GVAR(CADRepository) call ["pushHydratePayload", [_self]]
    }],
    ["handleHydrateResponse", compileFinal {
        params [["_payload", createHashMap, [createHashMap]]];

        if (isNil QGVAR(CADRepository)) exitWith { false };

        GVAR(CADRepository) call ["setHydratePayload", [_payload]];
        if !(_self call ["isDispatcher", []]) then {
            GVAR(CADRepository) call ["setMode", ["operations"]];
        };

        _self call ["refreshHydrate", []];
        _self call ["refreshTopBarState", []];
        _self call ["refreshDispatcher", []];
        _self call ["applyLayout", []]
    }],
    ["handleAssignmentResponse", compileFinal {
        params [["_result", createHashMap, [createHashMap]]];

        if (_self getOrDefault ["dispatcherReady", false]) then {
            private _dispatcherCtrl = _self call ["getDispatcherControl", []];
            if !(isNull _dispatcherCtrl) then {
                _dispatcherCtrl ctrlWebBrowserAction ["ExecJS", format [
                    "window.cadDispatcher && window.cadDispatcher.setStatus(%1, %2);",
                    str (_result getOrDefault ["message", "Task request processed."]),
                    str ([ "error", "success" ] select (_result getOrDefault ["success", false]))
                ]];
            };
        };

        _self call ["sendEvent", ["cad::assignment::response", createHashMapFromArray [
            ["message", _result getOrDefault ["message", "Task request processed."]],
            ["success", _result getOrDefault ["success", false]]
        ]]]
    }],
    ["handleGroupUpdateResponse", compileFinal {
        params [["_result", createHashMap, [createHashMap]]];

        if (_self getOrDefault ["dispatcherReady", false]) then {
            private _dispatcherCtrl = _self call ["getDispatcherControl", []];
            if !(isNull _dispatcherCtrl) then {
                _dispatcherCtrl ctrlWebBrowserAction ["ExecJS", format [
                    "window.cadDispatcher && window.cadDispatcher.setStatus(%1, %2);",
                    str (_result getOrDefault ["message", "Group update processed."]),
                    str ([ "error", "success" ] select (_result getOrDefault ["success", false]))
                ]];
            };
        };

        _self call ["sendEvent", ["cad::group::response", createHashMapFromArray [
            ["message", _result getOrDefault ["message", "Group update processed."]],
            ["success", _result getOrDefault ["success", false]]
        ]]]
    }],
    ["handleRequestResponse", compileFinal {
        params [["_result", createHashMap, [createHashMap]]];

        if (_self getOrDefault ["dispatcherReady", false]) then {
            private _dispatcherCtrl = _self call ["getDispatcherControl", []];
            if !(isNull _dispatcherCtrl) then {
                _dispatcherCtrl ctrlWebBrowserAction ["ExecJS", format [
                    "window.cadDispatcher && window.cadDispatcher.setStatus(%1, %2);",
                    str (_result getOrDefault ["message", "Request processed."]),
                    str (["error", "success"] select (_result getOrDefault ["success", false]))
                ]];
            };
        };

        _self call ["sendEvent", ["cad::request::response", createHashMapFromArray [
            ["message", _result getOrDefault ["message", "Request processed."]],
            ["success", _result getOrDefault ["success", false]]
        ]]]
    }]
];

GVAR(CADUIBridge) = createHashMapObject [GVAR(CADUIBridgeBaseClass)];
GVAR(CADUIBridge)
