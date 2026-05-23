#include "..\script_component.hpp"

/*
 * File: fnc_initRepository.sqf
 * Author: IDSolutions
 * Date: 2026-03-27
 * Public: No
 *
 * Description:
 * Initializes the locker repository for managing player locker items.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Locker repository object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_client_locker_fnc_initRepository;
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(LockerRepositoryBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "LockerRepositoryBaseClass"],
    ["#create", compileFinal {
        _self set ["uid", getPlayerUID player];
        _self set ["isLoaded", false];
        _self set ["lastSave", time];
        _self set ["locker", createHashMap];
    }],
    ["init", compileFinal {
        private _uid = _self get "uid";

        [SRPC(locker,requestInitLocker), [_uid]] call CFUNC(serverEvent);
        _self set ["lastSave", time];

        systemChat format ["Locker loaded for %1", name player];
        diag_log "[FORGE:Client:Locker] Locker Repository Initialized!";
    }],
    ["get", compileFinal {
        params [["_key", "", [""]], ["_default", nil, [[], "", 0, false, createHashMap]]];

        private _locker = _self get "locker";
        _locker getOrDefault [_key, _default];
    }],
    ["getCargo", compileFinal {
        params [["_container", objNull, [objNull]], ["_locker", createHashMap, [createHashMap]]];

        private _cargoData = [
            ["item", getItemCargo _container],
            ["weapon", getWeaponCargo _container],
            ["magazine", getMagazineCargo _container],
            ["backpack", getBackpackCargo _container]
        ];

        {
            _x params ["_category", "_data"];
            _data params ["_classes", "_counts"];

            {
                private _class = _x;
                private _count = _counts select _forEachIndex;

                _locker set [_class, createHashMapFromArray [
                    ["amount", _count],
                    ["classname", _class],
                    ["category", _category]
                ]];
            } forEach _classes;
        } forEach _cargoData;

        _locker
    }],
    ["getContainerItems", compileFinal {
        params [["_container", objNull, [objNull]], ["_locker", createHashMap, [createHashMap]]];

        private _allContainers = everyContainer _container;
        {
            _x params ["_containerClass", "_containerObj"];

            private _cfgVehicles = configFile >> "CfgVehicles" >> _containerClass;
            private _cfgWeapons = configFile >> "CfgWeapons" >> _containerClass;
            private _itemInfoType = getNumber (_cfgWeapons >> "ItemInfo" >> "type");
            private _isBackpack = isClass _cfgVehicles;
            private _isUniform = isClass _cfgWeapons && { _itemInfoType == TYPE_UNIFORM };
            private _isVest = isClass _cfgWeapons && { _itemInfoType == TYPE_VEST };

            if (!_isBackpack && !_isVest && !_isUniform) then { continue; };

            private _containerItems = getItemCargo _containerObj;
            _containerItems params ["_classes", "_counts"];
            {
                private _class = _x;
                private _count = _counts select _forEachIndex;
                private _existing = _locker getOrDefault [_class, createHashMap];
                private _existingCount = _existing getOrDefault ["amount", 0];

                _locker set [_class, createHashMapFromArray [
                    ["amount", _existingCount + _count],
                    ["classname", _class],
                    ["category", "item"]
                ]];
            } forEach _classes;

            private _containerMags = getMagazineCargo _containerObj;
            _containerMags params ["_classes", "_counts"];
            {
                private _class = _x;
                private _count = _counts select _forEachIndex;
                private _existing = _locker getOrDefault [_class, createHashMap];
                private _existingCount = _existing getOrDefault ["amount", 0];

                _locker set [_class, createHashMapFromArray [
                    ["amount", _existingCount + _count],
                    ["classname", _class],
                    ["category", "magazine"]
                ]];
            } forEach _classes;

            private _containerWeapons = getWeaponCargo _containerObj;
            _containerWeapons params ["_classes", "_counts"];
            {
                private _class = _x;
                private _count = _counts select _forEachIndex;
                private _existing = _locker getOrDefault [_class, createHashMap];
                private _existingCount = _existing getOrDefault ["amount", 0];

                _locker set [_class, createHashMapFromArray [
                    ["amount", _existingCount + _count],
                    ["classname", _class],
                    ["category", "weapon"]
                ]];
            } forEach _classes;
        } forEach _allContainers;

        _locker
    }],
    ["getAttachments", compileFinal {
        params [["_container", objNull, [objNull]], ["_locker", createHashMap, [createHashMap]]];

        private _weaponItems = weaponsItemsCargo _container;
        {
            private _muzzle = _x param [1, ""];
            private _pointer = _x param [2, ""];
            private _optic = _x param [3, ""];
            private _primaryMag = _x param [4, ["", 0]];
            private _underbarrel = _x param [5, ""];
            private _bipod = _x param [6, ""];
            private _secondaryMag = _x param [7, ["", 0]];
            private _attachments = [_muzzle, _pointer, _optic, _underbarrel, _bipod] select { (_x isEqualType "") && { _x != "" } };
            {
                private _existing = _locker getOrDefault [_x, createHashMap];
                private _existingCount = _existing getOrDefault ["amount", 0];

                _locker set [_x, createHashMapFromArray [
                    ["amount", _existingCount + 1],
                    ["classname", _x],
                    ["category", "item"]
                ]];
            } forEach _attachments;

            if (_primaryMag isNotEqualTo ["", 0]) then {
                _primaryMag params ["_magClass", "_ammoCount"];
                if (_magClass != "") then {
                    private _existing = _locker getOrDefault [_magClass, createHashMap];
                    private _existingCount = _existing getOrDefault ["amount", 0];

                    _locker set [_magClass, createHashMapFromArray [
                        ["amount", _existingCount + 1],
                        ["classname", _magClass],
                        ["category", "magazine"]
                    ]];
                };
            };

            if (_secondaryMag isNotEqualTo ["", 0]) then {
                _secondaryMag params ["_magClass", "_ammoCount"];
                if (_magClass != "") then {
                    private _existing = _locker getOrDefault [_magClass, createHashMap];
                    private _existingCount = _existing getOrDefault ["amount", 0];

                    _locker set [_magClass, createHashMapFromArray [
                        ["amount", _existingCount + 1],
                        ["classname", _magClass],
                        ["category", "magazine"]
                    ]];
                };
            };
        } forEach _weaponItems;

        _locker
    }],
    ["save", compileFinal {
        private _uid = _self get "uid";
        [SRPC(locker,requestSaveLocker), [_uid]] call CFUNC(serverEvent);

        _self set ["lastSave", time];
    }],
    ["setEventHandlers", compileFinal {
        params [["_locker", objNull, [objNull]]];

        _locker addEventHandler ["ContainerOpened", {
            params ["_container", "_unit"];

            private _index = GVAR(LockerRepository) get "locker";

            clearBackpackCargo _container;
            clearItemCargo _container;
            clearMagazineCargo _container;
            clearWeaponCargo _container;

            {
                private _amount = _y get "amount";
                private _category = _y get "category";
                private _className = _y get "classname";

                switch (_category) do {
                    case "backpack": { _container addBackpackCargo [_className, _amount]; };
                    case "item": { _container addItemCargo [_className, _amount]; };
                    case "magazine": { _container addMagazineCargo [_className, _amount]; };
                    case "weapon": { _container addWeaponCargo [_className, _amount]; };
                    default { _container addItemCargo [_className, _amount]; };
                };
            } forEach _index;

            if (count _index > 25) then {
                private _params = ["warning", "Over Capacity", "Locker has more then 25 items, please remove some items", 3000];
                GVAR(NotificationService) call ["create", _params];
            };
        }];

        _locker addEventHandler ["ContainerClosed", {
            params ["_container", "_unit"];

            private _newLocker = createHashMap;
            _newLocker = GVAR(LockerRepository) call ["getCargo", [_container, _newLocker]];
            _newLocker = GVAR(LockerRepository) call ["getContainerItems", [_container, _newLocker]];
            _newLocker = GVAR(LockerRepository) call ["getAttachments", [_container, _newLocker]];

            private _uid = getPlayerUID _unit;
            [SRPC(locker,requestOverrideLocker), [_uid, _newLocker]] call CFUNC(serverEvent);
            GVAR(LockerRepository) set ["locker", _newLocker];

            if (count _newLocker > 25) then {
                private _params = ["warning", "Over Capacity", "Locker has more then 25 items, please remove some items", 3000];
                GVAR(NotificationService) call ["create", _params];
            };
        }];
    }],
    ["setup", compileFinal {
        private _lockers = (allVariables missionNamespace) select {
            private _var = missionNamespace getVariable _x;
            ("locker" in _x) && { _var isEqualType objNull } && { !isNull _var } && { _x isNotEqualTo "forge_locker_box" }
        };

        if (_lockers isEqualTo []) exitWith { diag_log "[FORGE:Client:Locker] No lockers found in missionNamespace."; };

        {
            private _globalLocker = missionNamespace getVariable _x;
            private _pos = getPosASL _globalLocker;
            private _vDir = vectorDir _globalLocker;
            private _vUp = vectorUp _globalLocker;
            private _lockerClass = typeOf _globalLocker;
            if (_lockerClass isEqualTo "") then {
                _lockerClass = "Box_NATO_Equip_F";
            };

            private _localLocker = createVehicleLocal [_lockerClass, [0, 0, 0]];
            _localLocker setPosASL _pos;
            _localLocker setVectorDirAndUp [_vDir, _vUp];
            _localLocker allowDamage false;
            _localLocker setVariable ["isLocker", true];

            clearBackpackCargo _localLocker;
            clearItemCargo _localLocker;
            clearMagazineCargo _localLocker;
            clearWeaponCargo _localLocker;

            private _localVarName = format ["FORGE_Locker_Local_%1", _forEachIndex];
            _localLocker setVehicleVarName _localVarName;
            missionNamespace setVariable [_localVarName, _localLocker];

            _self call ["setEventHandlers", [_localLocker]];
        } forEach _lockers;
    }],
    ["sync", compileFinal {
        params [["_data", createHashMap, [createHashMap]]];

        private _isLoaded = _self get "isLoaded";
        private _locker = _self get "locker";

        { _locker set [_x, _y]; } forEach _data;
        _self set ["locker", _locker];

        if !(_isLoaded) then { _self set ["isLoaded", true]; _self call ["setup", []]; };
        diag_log "[FORGE:Client:Locker] Sync completed";
    }]
];

GVAR(LockerRepository) = createHashMapObject [GVAR(LockerRepositoryBaseClass)];
GVAR(LockerRepository)
