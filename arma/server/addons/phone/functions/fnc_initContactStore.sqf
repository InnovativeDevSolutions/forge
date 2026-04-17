#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Initialize contact store for phone contact management.
 *
 * Contact membership is owned by the extension phone hot-state service. SQF
 * enriches contact UIDs with live actor/player identity for the UI.
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(ContactStore) = createHashMapObject [[
    ["#type", "IContactStore"],
    ["#create", {
        diag_log "[FORGE:Server:Phone] Contact Store Initialized!";
    }],
    ["callPhoneArray", {
        params [["_function", "", [""]], ["_arguments", [], [[]]]];

        [_function, _arguments] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        if (!_isSuccess || { !(_result isEqualType "") }) exitWith { [] };
        if ((_result find "Error:") == 0) exitWith {
            diag_log format ["[FORGE:Server:Phone:Contact] Extension call %1 failed: %2", _function, _result];
            []
        };

        private _data = fromJSON _result;
        if !(_data isEqualType []) exitWith { [] };
        _data
    }],
    ["callPhoneBool", {
        params [["_function", "", [""]], ["_arguments", [], [[]]]];

        [_function, _arguments] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        if (!_isSuccess || { !(_result isEqualType "") }) exitWith { false };
        if ((_result find "Error:") == 0) exitWith {
            diag_log format ["[FORGE:Server:Phone:Contact] Extension call %1 failed: %2", _function, _result];
            false
        };

        _result isEqualTo "true"
    }],
    ["init", {
        params [["_uid", "", [""]]];

        if (_uid isEqualTo "") exitWith {
            diag_log "[FORGE:Server:Phone:Contact] Empty UID provided to init";
            false
        };

        private _fieldCommanderUid = "field_commander";
        _self call ["callPhoneBool", ["phone:contacts:add", [_uid, _uid]]];
        _self call ["callPhoneBool", ["phone:contacts:add", [_uid, _fieldCommanderUid]]];
        _self call ["refreshContacts", [_uid]];
        true
    }],
    ["addContact", {
        params [["_uid", "", [""]], ["_contactUid", "", [""]]];

        if (_uid isEqualTo "" || { _contactUid isEqualTo "" }) exitWith {
            diag_log "[FORGE:Server:Phone:Contact] Invalid UIDs provided to addContact";
            false
        };

        private _added = _self call ["callPhoneBool", ["phone:contacts:add", [_uid, _contactUid]]];
        if (_added) then { _self call ["refreshContacts", [_uid]]; };
        _added
    }],
    ["removeContact", {
        params [["_uid", "", [""]], ["_contactUid", "", [""]]];

        if (_uid isEqualTo "" || { _contactUid isEqualTo "" }) exitWith {
            diag_log "[FORGE:Server:Phone:Contact] Invalid UIDs provided to removeContact";
            false
        };

        private _removed = _self call ["callPhoneBool", ["phone:contacts:remove", [_uid, _contactUid]]];
        if (_removed) then { _self call ["refreshContacts", [_uid]]; };
        _removed
    }],
    ["resolveUidByActorField", {
        params [["_field", "", [""]], ["_value", "", [""]], ["_requesterUid", "", [""]]];

        if (_field isEqualTo "" || { _value isEqualTo "" }) exitWith { "" };

        private _normalizedValue = toLowerANSI _value;
        private _candidateUids = [];

        {
            private _candidateUid = getPlayerUID _x;
            if (_candidateUid isNotEqualTo "" && { !(_candidateUid in _candidateUids) }) then {
                _candidateUids pushBack _candidateUid;
            };
        } forEach allPlayers;

        {
            if (_x isNotEqualTo "" && { !(_x in _candidateUids) }) then {
                _candidateUids pushBack _x;
            };
        } forEach (EGVAR(actor,ActorStore) call ["listHotUids", []]);

        private _matchedUid = "";
        {
            private _candidateUid = _x;

            private _actorValue = EGVAR(actor,ActorStore) call ["getFieldOrDefault", [_candidateUid, _field, ""]];
            if (_actorValue isEqualType "" && { toLowerANSI _actorValue isEqualTo _normalizedValue }) exitWith {
                _matchedUid = _candidateUid;
            };
        } forEach _candidateUids;

        _matchedUid
    }],
    ["addContactByPhone", {
        params [["_uid", "", [""]], ["_phoneNumber", "", [""]]];

        private _contactUid = _self call ["resolveUidByActorField", ["phone_number", _phoneNumber, _uid]];
        if (_contactUid isEqualTo "") exitWith {
            diag_log format ["[FORGE:Server:Phone:Contact] Phone number %1 not found in hot actors", _phoneNumber];
            false
        };

        _self call ["addContact", [_uid, _contactUid]]
    }],
    ["addContactByEmail", {
        params [["_uid", "", [""]], ["_email", "", [""]]];

        private _contactUid = _self call ["resolveUidByActorField", ["email", _email, _uid]];
        if (_contactUid isEqualTo "") exitWith {
            diag_log format ["[FORGE:Server:Phone:Contact] Email %1 not found in hot actors", _email];
            false
        };

        _self call ["addContact", [_uid, _contactUid]]
    }],
    ["getContacts", {
        params [["_uid", "", [""]]];

        if (_uid isEqualTo "") exitWith { [] };
        _self call ["callPhoneArray", ["phone:contacts:list", [_uid]]]
    }],
    ["refreshContacts", {
        params [["_uid", "", [""]]];

        if (_uid isEqualTo "") exitWith {
            diag_log "[FORGE:Server:Phone:Contact] Empty UID provided to refreshContacts";
            []
        };

        private _contactObjects = [];
        private _fieldCommanderUid = "field_commander";
        private _fieldCommanderContact = createHashMapFromArray [
            ["uid", _fieldCommanderUid],
            ["name", "Field Cmdr"],
            ["fullName", "Field Commander"],
            ["phone", "0160000000"],
            ["email", "field_cmdr@spearnet.mil"],
            ["online", false],
            ["system", true],
            ["canCall", false],
            ["canMessage", false],
            ["canEmail", false]
        ];
        private _contactUids = _self call ["getContacts", [_uid]];
        if !(_fieldCommanderUid in _contactUids) then {
            _contactUids pushBack _fieldCommanderUid;
        };

        {
            private _contactUid = _x;
            if (_contactUid isEqualTo _fieldCommanderUid) then {
                _contactObjects pushBack _fieldCommanderContact;
                continue;
            };

            private _contactData = EGVAR(actor,ActorStore) call ["load", [_contactUid]];

            if (_contactData isNotEqualTo createHashMap) then {
                private _player = [_contactUid] call EFUNC(common,getPlayer);
                private _isOnline = !isNull _player;
                private _name = _contactData getOrDefault ["name", ""];
                if (_isOnline) then { _name = name _player; };
                if (_name isEqualTo "") then { _name = "Unknown Player"; };

                _contactObjects pushBack createHashMapFromArray [
                    ["uid", _contactUid],
                    ["name", _name],
                    ["fullName", _name],
                    ["phone", _contactData getOrDefault ["phone_number", ""]],
                    ["email", _contactData getOrDefault ["email", ""]],
                    ["online", _isOnline],
                    ["system", false],
                    ["canCall", true],
                    ["canMessage", true],
                    ["canEmail", true]
                ];
            };
        } forEach _contactUids;

        private _player = [_uid] call EFUNC(common,getPlayer);
        if (!isNull _player) then {
            _player setVariable ["FORGE_Contacts", _contactObjects, true];
        };

        _contactObjects
    }],
    ["remove", {
        params [["_uid", "", [""]]];
        if (_uid isEqualTo "") exitWith { false };

        ["phone:remove", [_uid]] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        _isSuccess && { _result isEqualTo "OK" }
    }]
]];

SETMVAR(FORGE_ContactStore,GVAR(ContactStore));
GVAR(ContactStore)
