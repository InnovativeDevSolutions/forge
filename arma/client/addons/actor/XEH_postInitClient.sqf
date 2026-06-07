#include "script_component.hpp"

removeAllWeapons player;
removeAllAssignedItems player;
removeUniform player;
removeVest player;
removeBackpack player;
removeGoggles player;
removeHeadgear player;

SETPVAR(player,FORGE_isLoaded,false);
cutText ["Loading In...", "BLACK", 1];

player addEventHandler ["Killed", {
    params ["_unit", "_killer", "_instigator", "_useEffects"];
    [SRPC(economy,onKilled), [_unit]] call CFUNC(serverEvent);
}];

player addEventHandler ["Respawn", {
    params ["_unit", "_corpse"];

    private _uid = getPlayerUID player;
    [SRPC(economy,onRespawn), [_unit, _corpse, _uid]] call CFUNC(serverEvent);
}];

if (isNil QGVAR(ActorRepository)) then { call FUNC(initRepository); true };

GVAR(resetMedicalSpectator) = {
    player switchMove "";
    player playMoveNow "";

    ["Terminate"] call BFUNC(EGSpectator);

    private _spectatorDisplay = findDisplay 60492;
    if !(isNull _spectatorDisplay) then { _spectatorDisplay closeDisplay 1; };
    if !(isNull player) then {
        player switchCamera "INTERNAL";
        player enableSimulation true;
    };

    cameraEffectEnableHUD true;
    showCinemaBorder false;
    disableUserInput false;
};

[QGVAR(initActor), {
    GVAR(ActorRepository) call ["init", []];
}] call CFUNC(addEventHandler);

[QGVAR(onActorRespawn), {
    params [["_loadout", [], [[]]], ["_medSpawnPos", [0,0,0], [[]]], ["_medSpawnDir", 0, [0]]];

    private _message = ["warning", "Medical Alert", "You have been revived at a medical facility.", 5000];
    EGVAR(notifications,NotificationService) call ["create", _message];

    player setUnitLoadout _loadout;
    player setPosATL _medSpawnPos;
    player setDir _medSpawnDir;
    player switchMove "Acts_LyingWounded_loop";

    [] spawn {
        ["Initialize", [player, [], false, true, true, true, true, true, false, false]] call BFUNC(EGSpectator);
        uiSleep 5;
        [SRPC(economy,onHealed), [player]] call CFUNC(serverEvent);
    };
}] call CFUNC(addEventHandler);

[QGVAR(onActorHealed), {
    call GVAR(resetMedicalSpectator);
}] call CFUNC(addEventHandler);

[QGVAR(responseInitActor), {
    params [["_data", createHashMap, [createHashMap]]];

    GVAR(ActorRepository) call ["sync", [_data, true]];
    cutText ["", "PLAIN", 1];
}] call CFUNC(addEventHandler);

[QGVAR(responseSyncActor), {
    params [["_data", createHashMap, [createHashMap]], ["_jip", false, [false]]];

    GVAR(ActorRepository) call ["sync", [_data, _jip]];
}] call CFUNC(addEventHandler);

[QGVAR(initActor), []] call CFUNC(localEvent);

[{
    GETVAR(player,FORGE_isLoaded,false)
}, {
    private _holster = GVAR(ActorRepository) call ["get", ["holster", true]];
    if (_holster) then { [player] call AFUNC(weaponselect,putWeaponAway); };
}] call CFUNC(waitUntilAndExecute);
