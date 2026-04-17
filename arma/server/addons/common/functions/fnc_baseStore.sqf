#include "..\script_component.hpp"

/*
 * File: fnc_baseStore.sqf
 * Author: IDSolutions
 * Date: 2026-01-08
 * Last Update: 2026-02-13
 * Public: No
 *
 * Description:
 * No description added yet.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Base store [HASHMAP]
 *
 * Example:
 * call forge_x_component_fnc_myFunction
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(BaseStore) = compileFinal createHashMapFromArray [
    ["#type", "IBaseStore"],
    ["fetch", {
        params [["_function", "", [""]], ["_key", "", [""]]];

        private _data = createHashMap;

        [_function, [_key]] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        ["INFO", format ["Data: %1", _result]] call EFUNC(common,log);

        if (_result isNotEqualTo []) then { _data = _self call ["toHashMap", [_result]] };

        _data
    }],
    ["get", {
        params [["_registry", createHashMap, [createHashMap]], ["_key", "", [""]], ["_field", "", [""]]];

        private _existingData = _registry get _key;
        private _finalData = createHashMap;

        if (_field isNotEqualTo "") then {
            _finalData = _existingData get _field
        } else {
            _finalData = _existingData
        };

        _finalData
    }],
    ["set", {
        params [["_registry", createHashMap, [createHashMap]], ["_function", "", [""]], ["_key", "", [""]], ["_field", "", [""]], ["_value", nil, [0, "", [], false, createHashMap, objNull, grpNull]], ["_sync", false, [false]]];

        private _existingData = _registry get _key;
        private _finalData = +_existingData;
        private _hashMap = createHashMap;

        _finalData set [_field, _value];
        _hashMap set [_field, _value];
        _registry set [_key, _finalData];

        if (_sync) then {
            private _json = _self call ["toJSON", [_hashMap]];
            [_function, [_key, _json]] call EFUNC(extension,extCall);
        };

        _hashMap
    }],
    ["mset", {
        params [["_registry", createHashMap, [createHashMap]], ["_function", "", [""]], ["_key", "", [""]], ["_fieldValuePairs", createHashMap, [createHashMap]], ["_sync", false, [false]]];

        private _existingData = _registry get _key;
        private _finalData = +_existingData;
        private _hashMap = createHashMap;

        { _finalData set [_x, _y]; } forEach _fieldValuePairs;
        { _hashMap set [_x, _y]; } forEach _fieldValuePairs;

        _registry set [_key, _finalData];

        if (_sync) then {
            private _json = _self call ["toJSON", [_hashMap]];
            [_function, [_key, _json]] call EFUNC(extension,extCall);
        };

        _hashMap
    }],
    ["save", {
        params [["_registry", createHashMap, [createHashMap]], ["_function", "", [""]], ["_key", "", [""]]];

        private _existingData = _registry get _key;
        private _finalData = +_existingData;
        private _json = _self call ["toJSON", [_finalData]];

        [_function, [_key, _json]] call EFUNC(extension,extCall);

        _finalData
    }],
    ["remove", {
        params [["_registry", createHashMap, [createHashMap]], ["_key", "", [""]]];

        _registry deleteAt _key;
    }],
    ["toHashMap", {
        params [["_data", "", [""]]];

        fromJSON _data
    }],
    ["toJSON", {
        params [["_data", createHashMap, [createHashMap]]];

        toJSON _data
    }]
];

GVAR(BaseStore)
