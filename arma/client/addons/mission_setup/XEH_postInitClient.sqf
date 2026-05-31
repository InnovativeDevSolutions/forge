#include "script_component.hpp"

if (isNil QGVAR(MissionSetupRepository)) then { call FUNC(initRepository); };

[CRPC(mission_setup,openMissionSetup), {
    diag_log "[FORGE:Client:MissionSetup] Received server open request.";
    [] call FUNC(openUI);
}] call CFUNC(addEventHandler);

[{
    GETVAR(player,FORGE_isLoaded,false)
}, {
    diag_log format [
        "[FORGE:Client:MissionSetup] Requesting mission setup open. Player=%1 VarName=%2",
        player,
        vehicleVarName player
    ];
    [SRPC(task,requestOpenMissionSetup), [player]] call CFUNC(serverEvent);
}] call CFUNC(waitUntilAndExecute);
