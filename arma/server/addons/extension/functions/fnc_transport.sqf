#include "..\script_component.hpp"

/*
 * File: fnc_transport.sqf
 * Author: IDSolutions
 * Date: 2026-04-01
 * Public: No
 *
 * Description:
 *     Shared transport helper for staging oversized requests and assembling
 *     chunked responses.
 *
 * Parameter(s):
 *     0: Mode <STRING>
 *        "stage": 1=function, 2=argumentsJson, 3=chunkSize, 4=invoker
 *        "assemble": 1=response, 2=success, 3=chunkPrefix, 4=chunkPrefixLength, 5=invoker
 *
 * Returns:
 *     Depends on mode.
 */

params [["_mode", "", [""]]];

switch (_mode) do {
    case "stage": {
        _this params [
            "_mode",
            ["_transportFunction", "", [""]],
            ["_argumentsJson", "", [""]],
            ["_requestChunkSize", 12000, [0]],
            ["_callExtensionCommand", {}, [{}]]
        ];

        private _transferID = format [
            "req_%1_%2",
            floor (diag_tickTime * 1000),
            floor (random 1000000000)
        ];

        for "_offset" from 0 to ((count toArray _argumentsJson) - 1) step _requestChunkSize do {
            private _chunk = _argumentsJson select [_offset, _requestChunkSize];

            ["transport:request:append", [_transferID, _chunk]] call _callExtensionCommand params [
                "_appendResult",
                "_appendSuccess"
            ];

            if (!_appendSuccess || { !(_appendResult isEqualType "") } || { (_appendResult find "Error:") == 0 }) exitWith {
                _transferID = "";
            };
        };

        if (_transferID isEqualTo "") exitWith {
            ["", [], false]
        };

        [
            "transport:invoke_stored",
            [_transportFunction, _transferID],
            true
        ]
    };

    case "assemble": {
        _this params [
            "_mode",
            ["_response", "", [""]],
            ["_responseSuccess", false, [true]],
            ["_chunkPrefix", "", [""]],
            ["_chunkPrefixLength", 0, [0]],
            ["_callExtensionCommand", {}, [{}]]
        ];

        if !(_responseSuccess && { _response isEqualType "" } && { (_response find _chunkPrefix) == 0 }) exitWith {
            [_response, _responseSuccess]
        };

        private _chunkEnvelope = fromJSON (_response select [_chunkPrefixLength]);
        if !(_chunkEnvelope isEqualType createHashMap) exitWith {
            ["Error: Invalid extension chunk envelope", false]
        };

        private _transferID = _chunkEnvelope getOrDefault ["transferId", ""];
        private _chunkCount = _chunkEnvelope getOrDefault ["chunkCount", 0];

        if (_transferID isEqualTo "" || { !(_chunkCount isEqualType 0) } || { _chunkCount < 1 }) exitWith {
            ["Error: Invalid extension chunk metadata", false]
        };

        private _assembledResponse = "";
        private _chunkReadSuccess = true;

        for "_index" from 0 to (_chunkCount - 1) do {
            ["transport:response:get", [_transferID, str _index]] call _callExtensionCommand params [
                "_chunkResult",
                "_chunkSuccess"
            ];

            if (!_chunkSuccess || { !(_chunkResult isEqualType "") } || { (_chunkResult find "Error:") == 0 }) exitWith {
                _chunkReadSuccess = false;
                _assembledResponse = "Error: Failed to retrieve chunked extension response";
            };

            _assembledResponse = _assembledResponse + _chunkResult;
        };

        ["transport:response:clear", [_transferID]] call _callExtensionCommand;

        [_assembledResponse, _chunkReadSuccess]
    };

    default {
        ["Error: Unsupported extension transport mode", false]
    };
};
