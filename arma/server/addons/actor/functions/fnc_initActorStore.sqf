#include "..\script_component.hpp"

/*
 * File: fnc_initActorStore.sqf
 * Author: IDSolutions
 * Date: 2025-12-17
 * Last Update: 2026-05-16
 * Public: Yes
 *
 * Description:
 * Initializes the actor store for managing player actor data.
 * Actor hot state is owned by the extension; SQF acts as a thin bridge for
 * engine-adjacent reads, snapshots, and response fan-out.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Actor store object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_server_actor_fnc_initActorStore
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(ActorModel) = compileFinal createHashMapObject [[
    ["#type", "ActorModel"],
    ["defaults", compileFinal {
        private _actor = createHashMap;

        _actor set ["uid", ""];
        _actor set ["name", ""];
        _actor set ["loadout", [[],[],[],["U_BG_Guerrilla_6_1",[["FirstAidKit", 2]]],[],[],"H_Cap_blk_ION","",[],["ItemMap","ItemGPS","ItemRadio","ItemCompass","ItemWatch",""]]];
        _actor set ["position", [0,0,0]];
        _actor set ["direction", 0];
        _actor set ["stance", "STAND"];
        _actor set ["rank", "PRIVATE"];
        _actor set ["state", "HEALTHY"];
        _actor set ["phone_number", ""];
        _actor set ["email", ""];
        _actor set ["organization", "default"];
        _actor set ["holster", true];

        _actor
    }],
    ["fromPlayer", compileFinal {
        params [["_player", objNull, [objNull]]];

        if (_player isEqualTo objNull) exitWith { _self call ["defaults", []] };

        private _actor = _self call ["defaults", []];

        _actor set ["uid", getPlayerUID _player];
        _actor set ["name", name _player];
        _actor set ["position", getPosASL _player];
        _actor set ["direction", getDir _player];
        _actor set ["stance", stance _player];
        _actor set ["rank", rank _player];
        _actor set ["state", lifeState _player];

        _actor
    }],
    ["migrate", compileFinal {
        params [["_actor", createHashMap, [createHashMap]]];

        private _defaults = _self call ["defaults", []];

        {
            if !(_x in _actor) then { _actor set [_x, _y]; };
        } forEach _defaults;

        _actor
    }],
    ["validate", compileFinal {
        params [["_actor", createHashMap, [createHashMap]]];

        private _uid = _actor getOrDefault ["uid", ""];
        private _name = _actor getOrDefault ["name", ""];
        private _position = _actor getOrDefault ["position", []];
        private _direction = _actor getOrDefault ["direction", 0];
        private _stance = _actor getOrDefault ["stance", ""];
        private _rank = _actor getOrDefault ["rank", ""];
        private _state = _actor getOrDefault ["state", ""];
        private _phone_number = _actor getOrDefault ["phone_number", ""];
        private _email = _actor getOrDefault ["email", ""];
        private _organization = _actor getOrDefault ["organization", ""];

        [_uid, _name, _position, _direction, _stance, _rank, _state, _phone_number, _email, _organization] try {
            if (_uid isEqualTo "" || !(_uid isEqualType "")) then { throw "Invalid UID!"; };
            if (_name isEqualTo "" || !(_name isEqualType "")) then { throw "Invalid Name!"; };
            if (_position isEqualTo [] || !(_position isEqualType [])) then { throw "Invalid Position!"; };
            if (_direction < 0 || !(_direction isEqualType 0)) then { throw "Invalid Direction!"; };
            if (_stance isEqualTo "" || !(_stance isEqualType "")) then { throw "Invalid Stance!"; };
            if (_rank isEqualTo "" || !(_rank isEqualType "")) then { throw "Invalid Rank!"; };
            if (_state isEqualTo "" || !(_state isEqualType "")) then { throw "Invalid State!"; };
            if (_phone_number isEqualTo "" || !(_phone_number isEqualType "")) then { throw "Invalid Phone Number!"; };
            if (_email isEqualTo "" || !(_email isEqualType "")) then { throw "Invalid Email!"; };
            if (_organization isEqualTo "" || !(_organization isEqualType "")) then { throw "Invalid Organization!"; };
        } catch {
            ["ERROR", format ["Failed to validate actor %1!", _exception]] call EFUNC(common,log);
            false
        };

        true
    }]
]];

GVAR(ActorBaseStore) = compileFinal ([
    EGVAR(common,BaseStore),
    createHashMapFromArray [
    ["#type", "ActorBaseStore"],
    ["#create", compileFinal {
        ["INFO", "Actor Store Initialized!"] call EFUNC(common,log);
        true
    }],
    ["cacheActor", compileFinal {
        params [["_uid", "", [""]], ["_actor", createHashMap, [createHashMap]]];

        if (_uid isEqualTo "" || { !(_actor isEqualType createHashMap) }) exitWith { createHashMap };

        GVAR(ActorModel) call ["migrate", [+_actor]]
    }],
    ["callHotActor", compileFinal {
        params [["_function", "", [""]], ["_arguments", [], [[]]]];

        if (_function isEqualTo "") exitWith { createHashMap };

        [_function, _arguments] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        if !(_isSuccess) exitWith { createHashMap };
        if !(_result isEqualType "") exitWith { createHashMap };
        if ((_result find "Error:") == 0) exitWith {
            ["ERROR", format ["Actor extension call '%1' failed: %2", _function, _result]] call EFUNC(common,log);
            createHashMap
        };

        private _data = fromJSON _result;
        if !(_data isEqualType createHashMap) exitWith { createHashMap };
        _data
    }],
    ["listHotUids", compileFinal {
        ["actor:hot:keys", []] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        if !(_isSuccess) exitWith { [] };
        if !(_result isEqualType "") exitWith { [] };
        if ((_result find "Error:") == 0) exitWith {
            ["ERROR", format ["Actor extension call '%1' failed: %2", "actor:hot:keys", _result]] call EFUNC(common,log);
            []
        };

        private _uids = fromJSON _result;
        if !(_uids isEqualType []) exitWith { [] };

        _uids select { _x isEqualType "" && { _x isNotEqualTo "" } }
    }],
    ["sendNewActorWelcomeComms", compileFinal {
        params [["_uid", "", [""]], ["_actor", createHashMap, [createHashMap]]];

        if (_uid isEqualTo "") exitWith { false };
        if (isNil QEGVAR(phone,PhoneStore)) exitWith {
            ["WARNING", format ["Unable to send new actor welcome comms for %1: phone store is unavailable.", _uid]] call EFUNC(common,log);
            false
        };

        EGVAR(phone,PhoneStore) call ["init", [_uid]];

        private _phoneNumber = _actor getOrDefault ["phone_number", ""];
        private _emailAddress = _actor getOrDefault ["email", ""];
        private _welcomeEmail = format [
            "Welcome to your first day on the job. Forge Dynamics has issued you a work phone with phone number %1 and email address %2. Keep these details handy for field communications and future assignments.",
            _phoneNumber,
            _emailAddress
        ];

        private _player = [_uid] call EFUNC(common,getPlayer);
        private _emailObj = EGVAR(phone,PhoneStore) call [
            "sendEmail",
            ["field_commander", _uid, "Job Orientation", _welcomeEmail]
        ];

        if (
            _emailObj isEqualType createHashMap
            && { _emailObj isNotEqualTo createHashMap }
            && { !(isNull _player) }
        ) then {
            ["forge_client_phone_responseEmailReceived", [_emailObj], _player] call CFUNC(targetEvent);
        };

        private _messages = [
            "Welcome to your first day on the job. Forge Dynamics has issued your starting equipment and a small account credit. These are the only free supplies you will receive for this identity, so use them wisely. You are responsible for all purchases going forward.",
            "Deposit your Earnings before leaving the session. Access the Bank from any laptop, then select Deposit Earnings."
        ];

        {
            private _messageObj = EGVAR(phone,PhoneStore) call [
                "sendMessage",
                ["field_commander", _uid, _x]
            ];
            if (
                _messageObj isEqualType createHashMap
                && { _messageObj isNotEqualTo createHashMap }
                && { !(isNull _player) }
            ) then {
                ["forge_client_phone_responseMessageReceived", [_messageObj], _player] call CFUNC(targetEvent);
            };
        } forEach _messages;

        true
    }],
    ["welcomeNewActor", compileFinal {
        params [["_uid", "", [""]], ["_actor", createHashMap, [createHashMap]]];

        if (_uid isEqualTo "") exitWith { false };

        _self call ["sendNewActorWelcomeComms", [_uid, _actor]];

        true
    }],
    ["loadHotActor", compileFinal {
        params [["_uid", "", [""]], ["_initialize", false, [false]]];

        if (_uid isEqualTo "") exitWith { createHashMap };
        if (_initialize) then {
            // Missing actors should be created explicitly from a server snapshot
            // before the hot cache is initialized.
            private _ensureResult = _self call ["ensurePersistentActor", [_uid]];
            if !(_ensureResult isEqualType true && { _ensureResult }) exitWith { createHashMap };
        };

        private _command = ["actor:hot:get", "actor:hot:init"] select _initialize;
        private _actor = _self call ["callHotActor", [_command, [_uid]]];
        if (_actor isEqualTo createHashMap) exitWith { _actor };

        _self call ["hydrateActorIfNeeded", [_uid, _actor, true]]
    }],
    ["ensurePersistentActor", compileFinal {
        params [["_uid", "", [""]]];

        if (_uid isEqualTo "") exitWith { false };

        ["actor:exists", [_uid]] call EFUNC(extension,extCall) params ["_existsResult", "_existsSuccess"];
        if (!_existsSuccess || { !(_existsResult isEqualType "") }) exitWith {
            ["ERROR", format ["Failed to verify persistent actor state for %1.", _uid]] call EFUNC(common,log);
            false
        };

        if (_existsResult isEqualTo "true") exitWith { true };

        private _player = [_uid] call EFUNC(common,getPlayer);
        private _actor = GVAR(ActorModel) call ["fromPlayer", [_player]];
        _actor set ["uid", _uid];

        if ((_actor getOrDefault ["organization", ""]) isEqualTo "") then {
            _actor set ["organization", "default"];
        };

        private _json = _self call ["toJSON", [_actor]];
        ["actor:create", [_uid, _json]] call EFUNC(extension,extCall) params ["_createResult", "_createSuccess"];

        if (!_createSuccess || { !(_createResult isEqualType "") }) exitWith {
            ["ERROR", format ["Failed to create actor %1 from server snapshot.", _uid]] call EFUNC(common,log);
            false
        };

        if ((_createResult find "Error:") == 0) exitWith {
            ["ERROR", format ["Actor create for %1 failed: %2", _uid, _createResult]] call EFUNC(common,log);
            false
        };

        private _createdActor = fromJSON _createResult;
        if !(_createdActor isEqualType createHashMap) then {
            _createdActor = +_actor;
        };
        _createdActor = GVAR(ActorModel) call ["migrate", [_createdActor]];
        true
    }],
    ["hydrateActorIfNeeded", compileFinal {
        params [["_uid", "", [""]], ["_actor", createHashMap, [createHashMap]], ["_save", true, [false]]];

        if (_uid isEqualTo "" || { !(_actor isEqualType createHashMap) } || { _actor isEqualTo createHashMap }) exitWith {
            createHashMap
        };

        // Hot actor reads can still surface older partial records. Repair them
        // from the live player snapshot when possible and persist the result.
        private _hydratedActor = GVAR(ActorModel) call ["migrate", [+_actor]];
        private _defaults = GVAR(ActorModel) call ["defaults", []];
        private _player = [_uid] call EFUNC(common,getPlayer);
        private _needsPersist = false;

        if ((_hydratedActor getOrDefault ["uid", ""]) isEqualTo "") then {
            _hydratedActor set ["uid", _uid];
            _needsPersist = true;
        };
        if ((_hydratedActor getOrDefault ["organization", ""]) isEqualTo "") then {
            _hydratedActor set ["organization", "default"];
            _needsPersist = true;
        };

        {
            private _value = _hydratedActor getOrDefault [_x, ""];
            if !(_value isEqualType "") then {
                _hydratedActor set [_x, _defaults getOrDefault [_x, ""]];
                _needsPersist = true;
            };
        } forEach ["phone_number", "email"];

        if (_player isNotEqualTo objNull) then {
            private _snapshot = GVAR(ActorModel) call ["fromPlayer", [_player]];
            private _name = _hydratedActor getOrDefault ["name", ""];
            if (
                !(_name isEqualType "")
                || { _name isEqualTo "" }
                || { toLowerANSI _name isEqualTo "unknown" }
            ) then {
                _hydratedActor set ["name", _snapshot getOrDefault ["name", name _player]];
                _needsPersist = true;
            };

            private _position = _hydratedActor getOrDefault ["position", []];
            if !(_position isEqualType [] && { count _position isEqualTo 3 }) then {
                _hydratedActor set ["position", _snapshot getOrDefault ["position", getPosASL _player]];
                _needsPersist = true;
            };

            private _direction = _hydratedActor getOrDefault ["direction", 0];
            if !(_direction isEqualType 0) then {
                _hydratedActor set ["direction", _snapshot getOrDefault ["direction", getDir _player]];
                _needsPersist = true;
            };

            {
                private _fieldValue = _hydratedActor getOrDefault [_x, ""];
                if (!(_fieldValue isEqualType "") || { _fieldValue isEqualTo "" }) then {
                    _hydratedActor set [_x, _snapshot getOrDefault [_x, _defaults getOrDefault [_x, ""]]];
                    _needsPersist = true;
                };
            } forEach ["stance", "rank", "state"];

            private _loadout = _hydratedActor getOrDefault ["loadout", []];
            if !(_loadout isEqualType [] && { count _loadout > 0 }) then {
                _hydratedActor set ["loadout", getUnitLoadout _player];
                _needsPersist = true;
            };
        } else {
            {
                private _fieldValue = _hydratedActor getOrDefault [_x, ""];
                if (!(_fieldValue isEqualType "") || { _fieldValue isEqualTo "" }) then {
                    _hydratedActor set [_x, _defaults getOrDefault [_x, ""]];
                    _needsPersist = true;
                };
            } forEach ["stance", "rank", "state"];
        };

        if !_needsPersist exitWith {
            _self call ["cacheActor", [_uid, _hydratedActor]]
        };

        private _updatedActor = _self call ["override", [_uid, _hydratedActor, _save]];
        if (_updatedActor isEqualType createHashMap && { _updatedActor isNotEqualTo createHashMap }) exitWith {
            _self call ["cacheActor", [_uid, _updatedActor]]
        };

        ["WARNING", format ["Failed to hydrate actor %1 from player snapshot.", _uid]] call EFUNC(common,log);
        _self call ["cacheActor", [_uid, _hydratedActor]]
    }],
    ["init", compileFinal {
        params [["_uid", "", [""]]];

        private _player = [_uid] call EFUNC(common,getPlayer);

        ["actor:exists", [_uid]] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        if !(_isSuccess) exitWith {
            ["ERROR", format ["Failed to check if actor %1 exists! Using fallback actor.", _uid]] call EFUNC(common,log);

            private _fallbackActor = GVAR(ActorModel) call ["fromPlayer", [_player]];
            _fallbackActor set ["uid", _uid];
            _fallbackActor = _self call ["cacheActor", [_uid, _fallbackActor]];

            [CRPC(actor,responseInitActor), [_fallbackActor], _player] call CFUNC(targetEvent);
            _fallbackActor
        };

        private _finalActor = createHashMap;
        if (_result == "true") then {
            _finalActor = _self call ["loadHotActor", [_uid, true]];
            ["INFO", format ["Found actor for %1", _uid]] call EFUNC(common,log);
        } else {
            if !(_self call ["ensurePersistentActor", [_uid]]) exitWith {
                ["ERROR", format ["Failed to create actor %1! Using fallback actor.", _uid]] call EFUNC(common,log);

                _finalActor = GVAR(ActorModel) call ["fromPlayer", [_player]];
                _finalActor set ["uid", _uid];
                _finalActor = _self call ["cacheActor", [_uid, _finalActor]];
                [CRPC(actor,responseInitActor), [_finalActor], _player] call CFUNC(targetEvent);
                _finalActor
            };

            _finalActor = _self call ["loadHotActor", [_uid, true]];
            ["INFO", format ["Created new actor for %1", _uid]] call EFUNC(common,log);
        };

        if (_finalActor isEqualTo createHashMap) then {
            _finalActor = GVAR(ActorModel) call ["fromPlayer", [_player]];
            _finalActor set ["uid", _uid];
        };

        _finalActor = _self call ["cacheActor", [_uid, _finalActor]];

        [CRPC(actor,responseInitActor), [_finalActor], _player] call CFUNC(targetEvent);
        _finalActor
    }],
    ["get", compileFinal {
        params [["_uid", "", [""]], ["_field", "", [""]]];

        private _actor = _self call ["loadHotActor", [_uid, false]];

        if (_field isEqualTo "") exitWith { _actor };
        _actor getOrDefault [_field, nil]
    }],
    ["load", compileFinal {
        params [["_uid", "", [""]]];

        private _actor = _self call ["get", [_uid, ""]];
        if !(_actor isEqualType createHashMap) exitWith { createHashMap };

        _actor
    }],
    ["getFieldOrDefault", compileFinal {
        params [["_uid", "", [""]], ["_field", "", [""]], ["_default", nil]];

        if (_uid isEqualTo "" || { _field isEqualTo "" }) exitWith { _default };

        private _actor = _self call ["load", [_uid]];
        if !(_actor isEqualType createHashMap) exitWith { _default };
        if (_actor isEqualTo createHashMap) exitWith { _default };

        _actor getOrDefault [_field, _default]
    }],
    ["getOrganization", compileFinal {
        params [["_uid", "", [""]], ["_default", "default", [""]]];

        private _orgID = _self call ["getFieldOrDefault", [_uid, "organization", _default]];
        if !(_orgID isEqualType "") exitWith { _default };
        if (_orgID isEqualTo "") exitWith { _default };

        _orgID
    }],
    ["getName", compileFinal {
        params [["_uid", "", [""]], ["_default", "", [""]]];

        private _name = _self call ["getFieldOrDefault", [_uid, "name", _default]];
        if !(_name isEqualType "") exitWith { _default };

        _name
    }],
    ["getPhoneNumber", compileFinal {
        params [["_uid", "", [""]], ["_default", "", [""]]];

        private _phoneNumber = _self call ["getFieldOrDefault", [_uid, "phone_number", _default]];
        if !(_phoneNumber isEqualType "") exitWith { _default };

        _phoneNumber
    }],
    ["override", compileFinal {
        params [
            ["_uid", "", [""]],
            ["_data", createHashMap, [createHashMap]],
            ["_save", false, [false]]
        ];

        if (_uid isEqualTo "" || { !(_data isEqualType createHashMap) }) exitWith { createHashMap };

        private _actor = _self call ["callHotActor", ["actor:hot:override", [_uid, toJSON _data]]];
        if (_save && { _actor isNotEqualTo createHashMap }) then {
            private _savedActor = _self call ["callHotActor", ["actor:hot:save", [_uid]]];
            if (_savedActor isNotEqualTo createHashMap) then {
                _actor = _savedActor;
            } else {
                _actor = createHashMap;
            };
        };

        if (_actor isEqualTo createHashMap) exitWith { _actor };
        _self call ["cacheActor", [_uid, _actor]]
    }],
    ["set", compileFinal {
        params [
            ["_uid", "", [""]],
            ["_field", "", [""]],
            ["_value", nil, [0, "", [], false, createHashMap, objNull, grpNull]],
            ["_sync", false, [false]]
        ];

        if (_uid isEqualTo "" || { _field isEqualTo "" }) exitWith { createHashMap };

        private _actor = _self call ["get", [_uid, ""]];
        if !(_actor isEqualType createHashMap) exitWith { createHashMap };

        _actor set [_field, _value];
        private _updatedActor = _self call ["override", [_uid, _actor, _sync]];
        if !(_updatedActor isEqualType createHashMap) exitWith { createHashMap };
        if (_updatedActor isEqualTo createHashMap) exitWith { createHashMap };

        createHashMapFromArray [[_field, _updatedActor getOrDefault [_field, _value]]]
    }],
    ["mset", compileFinal {
        params [["_uid", "", [""]], ["_fieldValuePairs", createHashMap, [createHashMap]], ["_sync", false, [false]]];

        if (_uid isEqualTo "" || { !(_fieldValuePairs isEqualType createHashMap) }) exitWith { createHashMap };

        private _actor = _self call ["get", [_uid, ""]];
        if !(_actor isEqualType createHashMap) exitWith { createHashMap };

        { _actor set [_x, _y]; } forEach _fieldValuePairs;
        private _updatedActor = _self call ["override", [_uid, _actor, _sync]];
        if !(_updatedActor isEqualType createHashMap) exitWith { createHashMap };
        if (_updatedActor isEqualTo createHashMap) exitWith { createHashMap };

        +_fieldValuePairs
    }],
    ["save", compileFinal {
        params [["_uid", "", [""]]];

        if (_uid isEqualTo "") exitWith { createHashMap };
        private _actor = _self call ["callHotActor", ["actor:hot:save", [_uid]]];
        if (_actor isEqualTo createHashMap) exitWith { _actor };

        _self call ["cacheActor", [_uid, _actor]]
    }],
    ["remove", compileFinal {
        params [["_uid", "", [""]]];

        if (_uid isEqualTo "") exitWith { false };

        ["actor:hot:remove", [_uid]] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        _isSuccess && { _result isEqualTo "OK" }
    }],
    ["snapshot", compileFinal {
        params [["_uid", "", [""]]];

        private _player = [_uid] call EFUNC(common,getPlayer);
        private _finalActor = +(_self call ["get", [_uid, ""]]);

        if (!(_finalActor isEqualType createHashMap) || (_finalActor isEqualTo createHashMap)) then {
            _finalActor = GVAR(ActorModel) call ["defaults", []];
            _finalActor set ["uid", _uid];
        };

        if (_player isNotEqualTo objNull) then {
            _finalActor set ["uid", _uid];
            _finalActor set ["name", name _player];
            _finalActor set ["position", getPosASL _player];
            _finalActor set ["direction", getDir _player];
            _finalActor set ["stance", stance _player];
            _finalActor set ["rank", rank _player];
            _finalActor set ["state", lifeState _player];
            _finalActor set ["loadout", getUnitLoadout _player];
            if ((_finalActor getOrDefault ["organization", ""]) isEqualTo "") then {
                _finalActor set ["organization", "default"];
            };
        } else {
            ["WARNING", format ["No player object found for %1 during actor snapshot, using cached values.", _uid]] call EFUNC(common,log);
        };

        _self call ["override", [_uid, _finalActor, false]]
    }]
]] call {
    params ["_base", "_child"];

    private _merged = +_base;
    { _merged set [_x, _y]; } forEach _child;
    _merged
});

GVAR(ActorStore) = createHashMapObject [GVAR(ActorBaseStore), []];
true
