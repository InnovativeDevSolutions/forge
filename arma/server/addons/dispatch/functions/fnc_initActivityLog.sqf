#include "..\script_component.hpp"

/*
 * File: fnc_initActivityLog.sqf
 * Author: IDSolutions
 * Date: 2026-11-10
 * Public: No
 *
 * Description:
 * Initializes the dispatch activity log: a short, transient feed of what
 * happened on the board, stored in the extension. Entries are written from
 * event listeners (see fnc_registerEventListeners) using player names.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Activity log object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_server_dispatch_fnc_initActivityLog
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(ActivityLogBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "DispatchActivityLogBaseClass"],
    ["append", compileFinal {
        params [
            ["_type", "", [""]],
            ["_message", "", [""]],
            ["_taskID", "", [""]],
            ["_groupID", "", [""]],
            ["_actorUid", "", [""]]
        ];

        if (_type isEqualTo "" || { _message isEqualTo "" }) exitWith { false };

        private _entry = createHashMapFromArray [
            ["type", _type],
            ["message", _message],
            ["taskId", _taskID],
            ["groupId", _groupID],
            ["actorUid", _actorUid],
            ["timestamp", serverTime]
        ];

        ["dispatch:activity:append", [toJSON _entry]] call EFUNC(extension,extCall) params ["_payload", "_isSuccess"];
        _isSuccess && { !(_payload isEqualType "") || { (_payload find "Error:") != 0 } }
    }],
    ["recent", compileFinal {
        params [["_limit", 50, [0]]];

        ["dispatch:activity:recent", [str _limit]] call EFUNC(extension,extCall) params ["_payload", "_isSuccess"];
        if (!_isSuccess || { !(_payload isEqualType "") } || { (_payload find "Error:") == 0 }) exitWith { [] };

        private _entries = fromJSON _payload;
        [[], _entries] select (_entries isEqualType [])
    }]
];

createHashMapObject [GVAR(ActivityLogBaseClass)]
