#include "script_component.hpp"

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

GVAR(PlayerBootstrapRegistry) = createHashMap;

if (isServer) then { "forge_server" callExtension ["surreal:reconnect", []]; };

["forge_icom_event", {
    params [["_event", "", [""]], ["_data", createHashMap, [createHashMap]]];

    systemChat format ["ICOM Event: %1", _event];
    diag_log format ["[ICOM] Event received: %1 | Data: %2", _event, _data];

    switch (_event) do {
        case "supply_drop": {
            systemChat "Supply drop event received";

            private _coords = _data getOrDefault ["coords", []];
            private _supplies = _data getOrDefault ["supplies", []];

            diag_log format ["[ICOM] Supply drop at %1 with supplies: %2", _coords, _supplies];
        };
        case "spawn_mission": {
            systemChat "Mission spawn event received";

            private _missionType = _data getOrDefault ["mission_type", ""];
            private _location = _data getOrDefault ["location", []];

            diag_log format ["[ICOM] Spawning mission type '%1' at %2", _missionType, _location];
        };
        case "global_alert": {
            systemChat "Global event received";

            private _message = _data getOrDefault ["message", ""];
            private _severity = _data getOrDefault ["severity", ""];

            diag_log format ["[ICOM] Global event '%1' severity: %2", _message, _severity];
        };
        default {
            diag_log format ["[ICOM] Unhandled event: %1", _event];
        };
    };
}] call CFUNC(addEventHandler);

diag_log "[ICOM] Event handler initialized";

addMissionEventHandler ["ExtensionCallback", {
    params ["_name", "_function", "_data"];

    if (_name isEqualTo "icom") then {
        ["forge_icom_event", (fromJSON _data)] call CFUNC(serverEvent);
    } else {
        (fromJSON _data) call (missionNamespace getVariable [_function, {
            diag_log "[FORGE:Server] Function does not exist!";
        }]);
    };
}];

addMissionEventHandler ["PlayerConnected", {
    params ["_id", "_uid", "_name", "_jip", "_owner", "_idStr"];
}];

addMissionEventHandler ["PlayerDisconnected", {
    params ["_id", "_uid", "_name", "_jip", "_owner", "_idStr"];

    if (_uid isEqualTo "") exitWith {};

    [_uid] call FUNC(saveHotState);
}];

addMissionEventHandler ["Ended", {
    [""] call FUNC(saveHotState);
}];

addMissionEventHandler ["MPEnded", {
    [""] call FUNC(saveHotState);
}];
