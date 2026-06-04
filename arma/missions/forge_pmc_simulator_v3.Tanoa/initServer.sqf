if (isServer) then {
    FORGE_curatorEligibleUids = [];

    FORGE_fnc_isCuratorEligibleUnit = {
        params [["_unit", objNull, [objNull]]];

        if (isNull _unit || { !isPlayer _unit }) exitWith { false };

        private _unitVar = toLowerANSI vehicleVarName _unit;
        private _uid = getPlayerUID _unit;
        private _adminLevel = admin (owner _unit);

        if (_unitVar isEqualTo "ceo" && { _uid isNotEqualTo "" }) then {
            FORGE_curatorEligibleUids pushBackUnique _uid;
        };

        (_unitVar isEqualTo "ceo") || { _uid in FORGE_curatorEligibleUids } || { _adminLevel > 0 }
    };

    FORGE_fnc_assignCuratorAccess = {
        {
            private _unit = _x;
            private _uid = getPlayerUID _unit;

            if (_uid isNotEqualTo "" && { alive _unit } && { isNull (getAssignedCuratorLogic _unit) }) then {
                private _curator = objNull;
                {
                    private _assignedUnit = getAssignedCuratorUnit _x;
                    if (isNull _assignedUnit) exitWith {
                        _curator = _x;
                    };

                    if (!alive _assignedUnit || { (getPlayerUID _assignedUnit) isEqualTo _uid }) exitWith {
                        unassignCurator _x;
                        _curator = _x;
                    };
                } forEach allCurators;

                if !(isNull _curator) then {
                    _unit assignCurator _curator;
                };
            };
        } forEach (allPlayers select { [_x] call FORGE_fnc_isCuratorEligibleUnit });
    };

    FORGE_fnc_refreshCuratorEditableObjects = {
        private _editableObjects = entities [[], ["Logic"], true, true];
        {
            _x addCuratorEditableObjects [_editableObjects, true];
        } forEach allCurators;
    };

    addMissionEventHandler ["EntityRespawned", {
        params ["_newEntity"];

        if (isPlayer _newEntity) then {
            [] spawn {
                sleep 1;
                call FORGE_fnc_assignCuratorAccess;
                call FORGE_fnc_refreshCuratorEditableObjects;
            };
        };
    }];

    [] spawn {
        while { true } do {
            call FORGE_fnc_assignCuratorAccess;
            call FORGE_fnc_refreshCuratorEditableObjects;
            sleep 10;
        };
    };
};
