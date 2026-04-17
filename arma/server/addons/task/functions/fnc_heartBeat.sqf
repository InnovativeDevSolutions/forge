#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Registers Entity and starts heartbeat
 *
 * Arguments:
 * 0: The entity <OBJECT>
 * 1: Type of the entity <STRING>
 * 2: The countdown timer <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_entity, "entity_type", 30] spawn FUNC(heartBeat);
 *
 * Public: Yes
 */

params [["_entity", nil, [objNull, 0, [], sideUnknown, grpNull, ""]], ["_typeOf", "", [""]], ["_time", 0, [0]]];

private _nearPlayers = [];

switch (_typeOf) do {
    case "hostage": {
		_entity setCaptive true;
		_entity enableAIFeature ["MOVE", false];
		_entity playMove "acts_executionvictim_loop";

		waitUntil {
			sleep 1;
			_nearPlayers = allPlayers inAreaArray [ASLToAGL getPosASL _entity, 2, 2, 0, false, 2];
			count _nearPlayers > 0
		};

		private _nearPlayer = _nearPlayers select 0;

		[_entity] joinSilent (group _nearPlayer);

		// Keep rescued hostages protected while they follow the player group.
		_entity setCaptive true;
		_entity enableAIFeature ["MOVE", true];
		_entity playMove "acts_executionvictim_unbow";
    };
    case "hvt": {
        waitUntil {
			sleep 1;
			_nearPlayers = allPlayers inAreaArray [ASLToAGL getPosASL _entity, 2, 2, 0, false, 2];
			count _nearPlayers > 0
		};

		_entity setCaptive true;
		doStop _entity;
    };
    case "ied": {
        private _taskID = _entity getVariable ["assignedTask", ""];
        if (_taskID isNotEqualTo "") then {
            waitUntil {
                sleep 1;
                GVAR(TaskStore) call ["isTaskAccepted", [_taskID]]
            };
        };

		while { alive _entity && _time > 0} do {
			if (_time > 10) then { _entity say3D "FORGE_timerBeep" };
			if (_time <= 10 && _time > 5) then { _entity say3D "FORGE_timerBeepShort" };
			if (_time <= 5) then { _entity say3D "FORGE_timerEnd" };
			if (_time <= 0) exitWith { _entity setDamage 1 };

			_time = _time -1;
			sleep 1;
		};

		if (alive _entity && _time <= 0) then { _entity setDamage 1 };
    };
};
