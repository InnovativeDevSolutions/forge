#include "..\script_component.hpp"

/*
 * File: fnc_initPersistenceService.sqf
 * Author: IDSolutions
 * Date: 2026-03-31
 * Public: No
 *
 * Description:
 * Initializes the CAD extension-state service that bridges live SQF
 * state to the Rust extension for hot CAD storage and recent history.
 *
 * This is a live operational cache, not a durable persistence layer.
 * CAD extension state is expected to reset with the current server or
 * mission lifecycle.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * CAD persistence service object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_server_cad_fnc_initPersistenceService
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(PersistenceServiceBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "CadPersistenceServiceBaseClass"],
    ["makeResult", compileFinal {
        params [
            ["_success", false, [false]],
            ["_data", nil, [createHashMap, []]]
        ];

        createHashMapFromArray [
            ["success", _success],
            ["data", _data]
        ]
    }],
    ["loadObject", compileFinal {
        params [["_function", "", [""]], ["_arguments", [], [[]]]];

        private _result = _self call ["makeResult", [false, createHashMap]];
        if (_function isEqualTo "") exitWith { _result };

        [_function, _arguments] call EFUNC(extension,extCall) params ["_payload", "_isSuccess"];
        if (!_isSuccess || { !(_payload isEqualType "") } || { (_payload find "Error:") == 0 }) exitWith {
            _result
        };

        private _data = fromJSON _payload;
        if !(_data isEqualType createHashMap) exitWith { _result };

        _result set ["success", true];
        _result set ["data", _data];
        _result
    }],
    ["loadCollection", compileFinal {
        params [["_function", "", [""]], ["_arguments", [], [[]]]];

        private _result = _self call ["makeResult", [false, []]];
        if (_function isEqualTo "") exitWith { _result };

        [_function, _arguments] call EFUNC(extension,extCall) params ["_payload", "_isSuccess"];
        if (!_isSuccess || { !(_payload isEqualType "") } || { (_payload find "Error:") == 0 }) exitWith {
            _result
        };

        private _data = fromJSON _payload;
        if !(_data isEqualType []) exitWith { _result };

        _result set ["success", true];
        _result set ["data", _data];
        _result
    }],
    ["loadRegistry", compileFinal {
        params [["_function", "", [""]], ["_idField", "", [""]]];

        private _result = _self call ["makeResult", [false, createHashMap]];
        if (_function isEqualTo "" || { _idField isEqualTo "" }) exitWith { _result };

        private _collectionResult = _self call ["loadCollection", [_function, []]];
        if !(_collectionResult getOrDefault ["success", false]) exitWith { _result };

        private _registry = createHashMap;
        {
            if !(_x isEqualType createHashMap) then { continue; };
            private _entryId = _x getOrDefault [_idField, ""];
            if (_entryId isEqualTo "") then { continue; };
            _registry set [_entryId, +_x];
        } forEach (_collectionResult getOrDefault ["data", []]);

        _result set ["success", true];
        _result set ["data", _registry];
        _result
    }],
    ["saveEntry", compileFinal {
        params [
            ["_function", "", [""]],
            ["_entryID", "", [""]],
            ["_entry", createHashMap, [createHashMap]]
        ];

        if (_function isEqualTo "" || { _entryID isEqualTo "" } || { _entry isEqualTo createHashMap }) exitWith { false };

        [_function, [_entryID, toJSON _entry]] call EFUNC(extension,extCall) params ["_payload", "_isSuccess"];
        _isSuccess && { !(_payload isEqualType "") || { (_payload find "Error:") != 0 } }
    }],
    ["deleteEntry", compileFinal {
        params [["_function", "", [""]], ["_entryID", "", [""]]];

        if (_function isEqualTo "" || { _entryID isEqualTo "" }) exitWith { false };

        [_function, [_entryID]] call EFUNC(extension,extCall) params ["_payload", "_isSuccess"];
        _isSuccess && { !(_payload isEqualType "") || { (_payload find "Error:") != 0 } }
    }],
    ["appendActivity", compileFinal {
        params [["_entry", createHashMap, [createHashMap]]];

        if (_entry isEqualTo createHashMap) exitWith { false };

        ["cad:activity:append", [toJSON _entry]] call EFUNC(extension,extCall) params ["_payload", "_isSuccess"];
        _isSuccess && { !(_payload isEqualType "") || { (_payload find "Error:") != 0 } }
    }],
    ["loadActivity", compileFinal {
        _self call ["loadCollection", ["cad:activity:recent", [str 50]]]
    }],
    ["buildHydratePayload", compileFinal {
        _self call ["loadObject", ["cad:view:hydrate", [toJSON (_this # 0)]]]
    }],
    ["loadAssignments", compileFinal {
        _self call ["loadRegistry", ["cad:assignments:list", "taskId"]]
    }],
    ["assignAssignment", compileFinal {
        _self call ["loadObject", ["cad:assignments:assign", [_this # 0, toJSON (_this # 1)]]]
    }],
    ["acknowledgeAssignment", compileFinal {
        _self call ["loadObject", ["cad:assignments:acknowledge", [_this # 0, toJSON (_this # 1)]]]
    }],
    ["declineAssignment", compileFinal {
        _self call ["loadObject", ["cad:assignments:decline", [_this # 0, toJSON (_this # 1)]]]
    }],
    ["saveAssignment", compileFinal {
        _self call ["saveEntry", ["cad:assignments:upsert", _this # 0, _this # 1]]
    }],
    ["deleteAssignment", compileFinal {
        _self call ["deleteEntry", ["cad:assignments:delete", _this # 0]]
    }],
    ["loadDispatchOrders", compileFinal {
        _self call ["loadRegistry", ["cad:orders:list", "taskID"]]
    }],
    ["createDispatchOrder", compileFinal {
        params [
            ["_orderSeed", createHashMap, [createHashMap]],
            ["_assignmentSeed", createHashMap, [createHashMap]]
        ];

        _self call ["loadObject", ["cad:orders:create", [toJSON (createHashMapFromArray [
            ["order", _orderSeed],
            ["assignment", _assignmentSeed]
        ])]]]
    }],
    ["createDispatchOrderFromContext", compileFinal {
        _self call ["loadObject", ["cad:orders:create_from_context", [toJSON (_this # 0)]]]
    }],
    ["closeDispatchOrder", compileFinal {
        _self call ["loadObject", ["cad:orders:close", [_this # 0]]]
    }],
    ["saveDispatchOrder", compileFinal {
        _self call ["saveEntry", ["cad:orders:upsert", _this # 0, _this # 1]]
    }],
    ["deleteDispatchOrder", compileFinal {
        _self call ["deleteEntry", ["cad:orders:delete", _this # 0]]
    }],
    ["loadRequests", compileFinal {
        _self call ["loadRegistry", ["cad:requests:list", "requestId"]]
    }],
    ["submitSupportRequest", compileFinal {
        _self call ["loadObject", ["cad:requests:submit", [toJSON (_this # 0)]]]
    }],
    ["submitSupportRequestFromContext", compileFinal {
        _self call ["loadObject", ["cad:requests:submit_from_context", [toJSON (_this # 0)]]]
    }],
    ["closeSupportRequest", compileFinal {
        _self call ["loadObject", ["cad:requests:close", [_this # 0]]]
    }],
    ["saveRequest", compileFinal {
        _self call ["saveEntry", ["cad:requests:upsert", _this # 0, _this # 1]]
    }],
    ["deleteRequest", compileFinal {
        _self call ["deleteEntry", ["cad:requests:delete", _this # 0]]
    }],
    ["loadGroupProfiles", compileFinal {
        _self call ["loadRegistry", ["cad:profiles:list", "groupId"]]
    }],
    ["buildGroups", compileFinal {
        _self call ["loadCollection", ["cad:groups:build", [toJSON (createHashMapFromArray [
            ["liveGroups", _this # 0]
        ])]]]
    }],
    ["updateGroupProfileFromContext", compileFinal {
        _self call ["loadObject", ["cad:profiles:update_from_context", [toJSON (_this # 0)]]]
    }],
    ["saveGroupProfile", compileFinal {
        _self call ["saveEntry", ["cad:profiles:upsert", _this # 0, _this # 1]]
    }],
    ["deleteGroupProfile", compileFinal {
        _self call ["deleteEntry", ["cad:profiles:delete", _this # 0]]
    }]
];

createHashMapObject [GVAR(PersistenceServiceBaseClass)]
