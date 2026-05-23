#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Spawns an enemy wave for a defense task
 *
 * Arguments:
 * 0: Defense zone marker name <STRING>
 * 1: Task ID <STRING>
 * 2: Wave number (0-based) <NUMBER>
 * 3: Enemy template groups <ARRAY> (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * ["defend_marker", "defend_1", 0] call forge_server_task_fnc_spawnEnemyWave;
 *
 * Public: No
 */

params [["_defenseZone", "", [""]], ["_taskID", "", [""]], ["_waveNumber", 0, [0]], ["_enemyTemplates", [], [[]]]];

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
    if (count _safePos > 0) then { _spawnPositions pushBack _safePos; };
};

private _groups = [];
if (_spawnPositions isEqualTo []) exitWith {
    ["ERROR", format ["Defense wave %1 for task %2 could not find spawn positions", _waveNumber + 1, _taskID]] call EFUNC(common,log);
};

if (_enemyTemplates isNotEqualTo []) then {
    private _groupCount = ((_waveNumber + 1) min 4) min (count _spawnPositions);
    private _selectedSpawnPositions = +_spawnPositions;
    _selectedSpawnPositions resize _groupCount;

    {
        private _spawnPos = _x;
        private _templateGroup = selectRandom _enemyTemplates;
        if !(_templateGroup isEqualType []) then { continue; };
        if (_templateGroup isEqualTo []) then { continue; };

        private _firstTemplate = _templateGroup select 0;
        if !(_firstTemplate isEqualType createHashMap) then { continue; };

        private _side = _firstTemplate getOrDefault ["side", east];
        private _group = createGroup _side;
        _groups pushBack _group;

        {
            private _unitTemplate = _x;
            if !(_unitTemplate isEqualType createHashMap) then { continue; };

            private _unitType = _unitTemplate getOrDefault ["type", "O_Soldier_F"];
            private _unit = _group createUnit [_unitType, _spawnPos, [], 0, "NONE"];
            _unit setVariable ["assignedTask", _taskID, true];
            _unit setUnitLoadout (_unitTemplate getOrDefault ["loadout", getUnitLoadout _unit]);
            _unit setSkill (_unitTemplate getOrDefault ["skill", skill _unit]);
            _unit setRank (_unitTemplate getOrDefault ["rank", rank _unit]);
            _unit setBehaviour "AWARE";
            _unit setSpeedMode "NORMAL";
            _unit enableDynamicSimulation true;
        } forEach _templateGroup;

        [_group, _center, _radius * 0.75] call CFUNC(taskDefend);
    } forEach _selectedSpawnPositions;

    ["INFO", format [
        "Spawned defense wave %1 for task %2 from %3 template group(s)",
        _waveNumber + 1,
        _taskID,
        count _groups
    ]] call EFUNC(common,log);
} else {
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

    ["INFO", format ["Spawned defense wave %1 for task %2 with %3 fallback units", _waveNumber + 1, _taskID, _unitCount]] call EFUNC(common,log);
};
