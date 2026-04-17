#include "..\script_component.hpp"

/*
 * File: fnc_extCall.sqf
 * Author: IDSolutions
 * Date: 2026-01-03
 * Last Update: 2026-04-28
 * Public: No
 *
 * Description:
 *     Call Forge Server extension.
 *
 * Parameter(s):
 *     0: Function name to call <STRING>
 *     1: Arguments to pass to function <ARRAY>
 *
 * Returns:
 *     Extension result <ARRAY>
 *     Success <BOOL>
 *
 * Example(s):
 *     ["icom:connect", ["127.0.0.1:9090", "server_1"]] call forge_x_component_fnc_extCall params ["_result", "_isSuccess"];
 */

params [["_function", "", [""]], ["_arguments", [], [[]]]];

private _quietFunctionLogs = [
    "task:defuse:get",
    "task:catalog:get"
];
private _functionLower = toLower _function;
if !(_functionLower in _quietFunctionLogs) then {
    ["INFO", format ["Calling function: %1", _function], nil, nil] call EFUNC(common,log);
};

private _chunkPrefix = "FORGE_TRANSPORT_CHUNK:";
private _chunkPrefixLength = count toArray _chunkPrefix;
private _unsupportedRoutePrefix = "Error: Unsupported transport route";
private _requestChunkSize = 12000;
// Keep bootstrap create/update calls on the direct extension path by default.
// Actor/bank initialization payloads are small enough for normal callExtension
// usage, and their correctness depends on preserving the native argument shape
// of [uid, json]. Transport remains available automatically for genuinely large
// requests through the chunked-request path below.
private _transportResponseFunctions = [
    "actor:get",
    "actor:hot:init",
    "actor:hot:get",
    "actor:hot:keys",
    "actor:hot:save",
    "bank:get",
    "bank:hot:init",
    "bank:hot:get",
    "bank:hot:save",
    "cad:view:hydrate",
    "cad:groups:build",
    "cad:assignments:list",
    "cad:orders:list",
    "cad:requests:list",
    "cad:activity:recent",
    "phone:init",
    "phone:contacts:list",
    "phone:messages:list",
    "phone:messages:thread",
    "phone:emails:list",
    "org:members:get",
    "org:assets:get",
    "org:fleet:get"
];
private _callExtensionCommand = {
    params [["_command", "", [""]], ["_commandArguments", [], [[]]]];

    ("forge_server" callExtension [_command, _commandArguments]) params [
        "_response",
        "_responseExtCode",
        "_responseArmaCode"
    ];

    private _responseSuccess = true;

    if (_responseArmaCode != 0 && _responseArmaCode != 301) then {
        _responseSuccess = false;

        private _armaCodeMessage = createHashMapFromArray [
            [101, "SYNTAX_ERROR_WRONG_PARAMS_SIZE"],
            [102, "SYNTAX_ERROR_WRONG_PARAMS_TYPE"],
            [201, "PARAMS_ERROR_TOO_MANY_ARGS"],
            [400, "EXTENSION_LOAD_FAILED"],
            [403, "EXTENSION_BLOCKED_BY_BATTLEYE"],
            [404, "EXTENSION_NOT_FOUND"]
        ] getOrDefault [_responseArmaCode, format ["UNKNOWN_%1", _responseArmaCode]];

        ["WARNING", format ["Arma error: %1", _armaCodeMessage], nil, nil] call EFUNC(common,log);
    };

    if (_responseExtCode != 0) then {
        _responseSuccess = false;

        if (_responseExtCode == -1) exitWith {
            ["WARNING", "Extension not available", nil, nil] call EFUNC(common,log);
            [_response, false]
        };

        if (_responseExtCode == 9) exitWith {
            ["WARNING", format ["Extension error: %1", _response], nil, nil] call EFUNC(common,log);
            [_response, false]
        };

        ["WARNING", format ["Extension error: %1", _responseExtCode], nil, nil] call EFUNC(common,log);
    };

    [_response, _responseSuccess]
};

private _buildTransportArgumentsJson = {
    private _rawArguments = _this;
    if !(_rawArguments isEqualType []) then {
        _rawArguments = [_rawArguments];
    };

    private _stringArguments = _rawArguments apply {
        if (_x isEqualType "") exitWith { _x };
        if (_x isEqualType true) exitWith { ["false", "true"] select _x };
        str _x
    };

    if !(_stringArguments isEqualType []) then {
        _stringArguments = [_stringArguments];
    };

    private _encodedArguments = [];
    {
        _encodedArguments pushBack (toJSON _x);
    } forEach _stringArguments;

    format ["[%1]", _encodedArguments joinString ","]
};

if (_functionLower in ["status", "version"]) exitWith {
    [_function, _arguments] call _callExtensionCommand
};

private _argumentsJson = _arguments call _buildTransportArgumentsJson;
private _usesTransportResponse = _functionLower in _transportResponseFunctions;
private _usesChunkedRequest = (count toArray _argumentsJson) > _requestChunkSize;

// Most calls should stay direct unless they either need chunked response
// assembly or the request body is large enough to require staging.
if !(_usesTransportResponse || { _usesChunkedRequest }) exitWith {
    [_function, _arguments] call _callExtensionCommand
};

private _transportCommand = "transport:invoke";
private _transportArguments = [_function, _argumentsJson];

if (_usesChunkedRequest) then {
    ["stage", _function, _argumentsJson, _requestChunkSize, _callExtensionCommand] call FUNC(transport) params [
        "_stagedTransportCommand",
        "_stagedTransportArguments",
        "_stageSuccess"
    ];

    if (!_stageSuccess) exitWith {
        ["Error: Failed to stage chunked extension request", false]
    };

    _transportCommand = _stagedTransportCommand;
    _transportArguments = _stagedTransportArguments;
};

[_transportCommand, _transportArguments] call _callExtensionCommand params ["_result", "_success"];

if (
    _success
    && { _result isEqualType "" }
    && { (_result find _unsupportedRoutePrefix) == 0 }
    && { !_usesChunkedRequest }
) exitWith {
    [_function, _arguments] call _callExtensionCommand
};

["assemble", _result, _success, _chunkPrefix, _chunkPrefixLength, _callExtensionCommand] call FUNC(transport)
