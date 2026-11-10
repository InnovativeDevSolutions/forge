#include "..\script_component.hpp"

/*
 * File: fnc_initDispatchStore.sqf
 * Author: IDSolutions
 * Date: 2026-11-10
 * Public: Yes
 *
 * Description:
 * Initializes the dispatch store, which adds dispatcher tooling on top of
 * CAD: dispatch orders, support requests, the activity feed and generated
 * mission requests. It registers a CAD hydrate contributor so the CAD UI
 * receives `requests`, `activity` and `generatedTaskTypes`.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Dispatch store object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_server_dispatch_fnc_initDispatchStore
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(DispatchStoreBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "DispatchStoreBaseClass"],
    ["#create", compileFinal {
        _self set ["OrderService", call FUNC(initOrderService)];
        _self set ["RequestService", call FUNC(initRequestService)];
        _self set ["ActivityLog", call FUNC(initActivityLog)];

        ["INFO", "Dispatch Store Initialized!"] call EFUNC(common,log);
    }],
    ["canDispatch", compileFinal {
        params [["_uid", "", [""]]];
        (EGVAR(cad,CadStore) get "PermissionService") call ["canDispatch", [_uid]]
    }],
    ["emitEvent", compileFinal {
        params [["_eventName", "", [""]], ["_payload", createHashMap, [createHashMap]]];

        if (isNil QEGVAR(common,EventBus)) exitWith { false };
        EGVAR(common,EventBus) call ["emit", [_eventName, _payload, createHashMapFromArray [["source", "dispatch"]]]];
        true
    }],
    ["handleRpc", compileFinal {
        params [
            ["_uid", "", [""]],
            ["_responseRpc", "", [""]],
            ["_method", "", [""]],
            ["_arguments", [], [[]]]
        ];

        private _player = EGVAR(cad,CadStore) call ["resolveRequestPlayer", [_uid, format ["Dispatch %1 request received with empty UID.", _method]]];
        if (isNull _player) exitWith { createHashMap };

        private _result = _self call [_method, _arguments];
        [_responseRpc, [_result], _player] call CFUNC(targetEvent);

        if (_result getOrDefault ["success", false]) then {
            EGVAR(cad,CadStore) call ["invalidateClients", []];
        };
        _result
    }],

    ["createOrder", compileFinal {
        private _result = (_self get "OrderService") call ["create", _this];
        if (_result getOrDefault ["success", false]) then {
            _self call ["emitEvent", ["dispatch.order.created", _result]];
        };
        _result
    }],
    ["closeOrder", compileFinal {
        private _result = (_self get "OrderService") call ["close", _this];
        if (_result getOrDefault ["success", false]) then {
            _self call ["emitEvent", ["dispatch.order.closed", _result]];
        };
        _result
    }],
    ["submitRequest", compileFinal {
        private _result = (_self get "RequestService") call ["submit", _this];
        if (_result getOrDefault ["success", false]) then {
            _self call ["emitEvent", ["dispatch.request.submitted", _result]];
        };
        _result
    }],
    ["closeRequest", compileFinal {
        private _result = (_self get "RequestService") call ["close", _this];
        if (_result getOrDefault ["success", false]) then {
            _self call ["emitEvent", ["dispatch.request.closed", _result]];
        };
        _result
    }],
    ["requestGeneratedMission", compileFinal {
        params [["_uid", "", [""]], ["_taskType", "", [""]], ["_metadata", createHashMap, [createHashMap]]];

        private _result = createHashMapFromArray [["success", false], ["message", "Generated task request failed."]];

        if (_taskType isEqualTo "") exitWith {
            _result set ["message", "Select a task type before requesting a generated task."];
            _result
        };
        if !(_self call ["canDispatch", [_uid]]) exitWith {
            _result set ["message", "Only dispatchers can request generated tasks."];
            _result
        };
        if (isNil QEGVAR(task,MissionGeneratorProviderRegistry)) exitWith {
            _result set ["message", "Generated mission provider registry is unavailable."];
            _result
        };

        EGVAR(task,MissionGeneratorProviderRegistry) call ["requestMissionTask", [_taskType, _metadata, _uid]]
    }],

    ["buildHydrateSection", compileFinal {
        params [["_uid", "", [""]], ["_session", createHashMap, [createHashMap]], ["_payload", createHashMap, [createHashMap]]];

        (_self get "OrderService") call ["refreshOrderPositions", [_payload]];

        private _isDispatcher = _session getOrDefault ["isDispatcher", false];
        private _groupID = _session getOrDefault ["groupId", ""];
        private _requests = ((_self get "RequestService") call ["list", []]) select {
            _isDispatcher || { (_x getOrDefault ["groupId", ""]) isEqualTo _groupID }
        };

        private _generatedTaskTypes = [];
        if (_isDispatcher && { !(isNil QEGVAR(task,MissionGeneratorProviderRegistry)) }) then {
            _generatedTaskTypes = EGVAR(task,MissionGeneratorProviderRegistry) call ["getGeneratedTaskTypes", []];
        };

        createHashMapFromArray [
            ["dispatchEnabled", true],
            ["requests", _requests],
            ["activity", (_self get "ActivityLog") call ["recent", [50]]],
            ["generatedTaskTypes", _generatedTaskTypes]
        ]
    }]
];

GVAR(DispatchStore) = createHashMapObject [GVAR(DispatchStoreBaseClass)];

EGVAR(cad,CadStore) call ["registerHydrateContributor", ["dispatch", {
    GVAR(DispatchStore) call ["buildHydrateSection", _this]
}]];

GVAR(DispatchStore)
