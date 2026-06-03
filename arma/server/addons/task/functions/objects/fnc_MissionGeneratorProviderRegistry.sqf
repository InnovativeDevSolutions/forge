#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Registry object for generated mission providers used by CAD/manual requests.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Mission generator provider registry object <HASHMAP OBJECT>
 *
 * Public: No
 */

if !(isServer) exitWith { createHashMap };

#pragma hemtt ignore_variables ["_self"]
GVAR(MissionGeneratorProviderRegistryBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "MissionGeneratorProviderRegistryBaseClass"],
    ["#create", compileFinal {
        _self set ["providers", createHashMap];
    }],
    ["emptyResult", compileFinal {
        params [
            ["_message", "Generated task request failed.", [""]],
            ["_taskType", "", [""]]
        ];

        createHashMapFromArray [
            ["success", false],
            ["message", _message],
            ["taskID", ""],
            ["taskType", _taskType]
        ]
    }],
    ["normalizeProviderId", compileFinal {
        params [["_providerId", "builtin", [""]]];

        _providerId = toLowerANSI _providerId;
        if (_providerId isEqualTo "") then { _providerId = "builtin"; };
        _providerId
    }],
    ["registerProvider", compileFinal {
        params [
            ["_providerId", "", [""]],
            ["_provider", createHashMap, [createHashMap]]
        ];

        _providerId = _self call ["normalizeProviderId", [_providerId]];
        if (_provider isEqualTo createHashMap) exitWith {
            ["WARNING", format ["Generated mission provider registration ignored: provider '%1' was empty.", _providerId]] call EFUNC(common,log);
            false
        };
        if !("getGeneratedTaskTypes" in _provider) exitWith {
            ["WARNING", format ["Generated mission provider registration ignored: provider '%1' has no getGeneratedTaskTypes method.", _providerId]] call EFUNC(common,log);
            false
        };
        if !("requestMissionTask" in _provider) exitWith {
            ["WARNING", format ["Generated mission provider registration ignored: provider '%1' has no requestMissionTask method.", _providerId]] call EFUNC(common,log);
            false
        };

        (_self get "providers") set [_providerId, _provider];
        ["INFO", format ["Generated mission provider registered. Provider=%1", _providerId]] call EFUNC(common,log);
        true
    }],
    ["hasProvider", compileFinal {
        params [["_providerId", "builtin", [""]]];

        _providerId = _self call ["normalizeProviderId", [_providerId]];
        _providerId in (_self getOrDefault ["providers", createHashMap])
    }],
    ["getProvider", compileFinal {
        params [["_providerId", "builtin", [""]]];

        _providerId = _self call ["normalizeProviderId", [_providerId]];
        (_self getOrDefault ["providers", createHashMap]) getOrDefault [_providerId, createHashMap]
    }],
    ["getSelectedProviderId", compileFinal {
        private _providerId = _self call ["normalizeProviderId", [GETGVAR(generatorProvider,"builtin")]];
        if (_self call ["hasProvider", [_providerId]]) exitWith { _providerId };

        ["WARNING", format [
            "Generated mission provider '%1' is selected but not registered; falling back to builtin provider.",
            _providerId
        ]] call EFUNC(common,log);
        "builtin"
    }],
    ["getActiveProvider", compileFinal {
        _self call ["getProvider", [_self call ["getSelectedProviderId", []]]]
    }],
    ["getGeneratedTaskTypes", compileFinal {
        private _providerId = _self call ["getSelectedProviderId", []];
        private _provider = _self call ["getProvider", [_providerId]];
        if (_provider isEqualTo createHashMap) exitWith { [] };

        private _types = _provider call ["getGeneratedTaskTypes", []];
        if !(_types isEqualType []) exitWith {
            ["WARNING", format ["Generated mission provider '%1' returned invalid task types.", _providerId]] call EFUNC(common,log);
            []
        };

        ["INFO", format [
            "Generated mission provider '%1' returned task types: %2",
            _providerId,
            _types apply { _x getOrDefault ["value", ""] }
        ]] call EFUNC(common,log);
        _types
    }],
    ["requestMissionTask", compileFinal {
        params [
            ["_requestedType", "", [""]],
            ["_metadata", createHashMap, [createHashMap]],
            ["_requesterUid", "", [""]]
        ];

        private _providerId = _self call ["getSelectedProviderId", []];
        private _provider = _self call ["getProvider", [_providerId]];
        if (_provider isEqualTo createHashMap) exitWith {
            _self call ["emptyResult", [format ["Generated mission provider is unavailable: %1", _providerId], _requestedType]]
        };

        private _result = _provider call ["requestMissionTask", [_requestedType, _metadata, _requesterUid]];
        if !(_result isEqualType createHashMap) exitWith {
            _self call ["emptyResult", [format ["Generated mission provider '%1' returned an invalid request result.", _providerId], _requestedType]]
        };

        if !("taskType" in _result) then { _result set ["taskType", _requestedType]; };
        if !("taskID" in _result) then { _result set ["taskID", ""]; };
        if !("success" in _result) then { _result set ["success", false]; };
        if !("message" in _result) then { _result set ["message", "Generated task request completed."]; };
        _result set ["provider", _providerId];
        _result
    }]
];

GVAR(MissionGeneratorProviderRegistry) = createHashMapObject [GVAR(MissionGeneratorProviderRegistryBaseClass)];
GVAR(MissionGeneratorProviderRegistry)
