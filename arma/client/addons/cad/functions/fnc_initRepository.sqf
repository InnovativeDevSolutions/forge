#include "..\script_component.hpp"

/*
 * File: fnc_initRepository.sqf
 * Author: IDSolutions
 * Date: 2026-03-28
 * Public: No
 *
 * Description:
 * Initializes the CAD repository for lightweight client lifecycle state.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * CAD repository object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_client_cad_fnc_initRepository
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(CADRepository) = createHashMapObject [[
    ["#type", "CADRepository"],
    ["#create", compileFinal {
        _self set ["isLoaded", true];
        _self set ["isOpen", false];
        _self set ["groups", []];
        _self set ["contracts", []];
        _self set ["requests", []];
        _self set ["assignments", []];
        _self set ["activity", []];
        _self set ["session", createHashMap];
        _self set ["mode", "operations"];
        _self set ["dispatchView", "board"];
    }],
    ["getHydratePayload", compileFinal {
        createHashMapFromArray [
            ["groups", +(_self getOrDefault ["groups", []])],
            ["contracts", +(_self getOrDefault ["contracts", []])],
            ["requests", +(_self getOrDefault ["requests", []])],
            ["assignments", +(_self getOrDefault ["assignments", []])],
            ["activity", +(_self getOrDefault ["activity", []])],
            ["session", +(_self getOrDefault ["session", createHashMap])],
            ["mode", _self getOrDefault ["mode", "operations"]],
            ["dispatchView", _self getOrDefault ["dispatchView", "board"]]
        ]
    }],
    ["getCurrentGroup", compileFinal {
        private _session = _self getOrDefault ["session", createHashMap];
        private _groupID = _session getOrDefault ["groupId", ""];
        if (_groupID isEqualTo "") exitWith { createHashMap };

        private _groups = _self getOrDefault ["groups", []];
        private _group = _groups findIf { (_x getOrDefault ["groupId", ""]) isEqualTo _groupID };
        if (_group < 0) exitWith { createHashMap };

        +(_groups # _group)
    }],
    ["pushHydratePayload", compileFinal {
        params [["_bridge", createHashMap, [createHashMap]]];

        if (_bridge isEqualTo createHashMap) exitWith { false };

        _bridge call ["sendEvent", ["cad::hydrate", _self call ["getHydratePayload", []]]]
    }],
    ["setHydratePayload", compileFinal {
        params [["_payload", createHashMap, [createHashMap]]];

        _self set ["groups", +(_payload getOrDefault ["groups", []])];
        _self set ["contracts", +(_payload getOrDefault ["contracts", []])];
        _self set ["requests", +(_payload getOrDefault ["requests", []])];
        _self set ["assignments", +(_payload getOrDefault ["assignments", []])];
        _self set ["activity", +(_payload getOrDefault ["activity", []])];
        _self set ["session", +(_payload getOrDefault ["session", createHashMap])];
        true
    }],
    ["setMode", compileFinal {
        params [["_mode", "operations", [""]]];

        if !(_mode in ["operations", "dispatch"]) then {
            _mode = "operations";
        };

        _self set ["mode", _mode];
        _mode
    }],
    ["setDispatchView", compileFinal {
        params [["_dispatchView", "board", [""]]];

        if !(_dispatchView in ["board", "map"]) then {
            _dispatchView = "board";
        };

        _self set ["dispatchView", _dispatchView];
        _dispatchView
    }],
    ["setOpen", compileFinal {
        params [["_isOpen", false, [false]]];
        _self set ["isOpen", _isOpen];
        true
    }]
]];

GVAR(CADRepository)
