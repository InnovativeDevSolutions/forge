#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Spawns an enemy wave for a defense task
 *
 * Arguments:
 * 0: Defense zone marker name <STRING>
 * 1: Task ID <STRING>
 * 2: Wave number (0-based) <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["defend_marker", "defend_1", 0] call forge_server_task_fnc_spawnEnemyWave;
 *
 * Public: No
 */

params [["_defenseZone", "", [""]], ["_taskID", "", [""]], ["_waveNumber", 0, [0]]];

if (_defenseZone == "") exitWith { ["ERROR", "No defense zone provided for enemy wave spawn"] call EFUNC(common,log); };

// TODO: Add unit types to mission config
private _basicTypes = ["O_Soldier_F", "O_Soldier_AR_F", "O_Soldier_GL_F", "O_medic_F"];
private _specialTypes = ["O_Soldier_LAT_F", "O_soldier_M_F", "O_Soldier_TL_F", "O_Soldier_SL_F"];
private _eliteTypes = ["O_Soldier_HAT_F", "O_Soldier_AA_F", "O_engineer_F", "O_Sharpshooter_F"];

private _unitCount = 6 + (_waveNumber * 2); // TODO: Make this configurable in mission config
private _specialChance = 0.2 + (_waveNumber * 0.1); // TODO: Make this configurable in mission config
private _eliteChance = (_waveNumber * 0.05); // TODO: Make this configurable in mission config

private _center = getMarkerPos _defenseZone;
private _radius = (getMarkerSize _defenseZone select 0) max (getMarkerSize _defenseZone select 1);
private _spawnRadius = _radius + 150;
private _spawnPositions = [];

for "_i" from 0 to 3 do {
    private _angle = _i * 90;
    private _variance = 45;
    private _spawnAngle = _angle + (random (_variance * 2) - _variance);
    private _spawnDist = _spawnRadius + (random 50 - 25);

    private _spawnX = (_center select 0) + (_spawnDist * cos _spawnAngle);
    private _spawnY = (_center select 1) + (_spawnDist * sin _spawnAngle);
    private _spawnPos = [_spawnX, _spawnY, 0];

    private _safePos = _spawnPos findEmptyPosition [0, 50, "O_Soldier_F"];
    if (count _safePos > 0) then {
        _spawnPositions pushBack _safePos;
    };
};

private _groups = [];
{
    private _groupSize = ceil(_unitCount / (count _spawnPositions));
    private _group = createGroup east;
    _groups pushBack _group;

    for "_i" from 1 to _groupSize do {
        private _unitType = _basicTypes select (floor random count _basicTypes);
        private _roll = random 1;

        if (_roll < _eliteChance) then {
            _unitType = _eliteTypes select (floor random count _eliteTypes);
        } else {
            if (_roll < _specialChance) then {
                _unitType = _specialTypes select (floor random count _specialTypes);
            };
        };

        private _unit = _group createUnit [_unitType, _x, [], 0, "NONE"];
        _unit setVariable ["assignedTask", _taskID, true];
        _unit setBehaviour "AWARE";
        _unit setSpeedMode "NORMAL";
        _unit enableDynamicSimulation true;
    };

    [_group, _center, _radius * 0.75] call CFUNC(taskDefend);
} forEach _spawnPositions;

["INFO", format ["Spawned defense wave %1 for task %2 with %3 units", _waveNumber + 1, _taskID, _unitCount]] call EFUNC(common,log);
