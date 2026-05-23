#include "..\script_component.hpp"

/*
 * File: fnc_initCatalogService.sqf
 * Author: IDSolutions
 * Date: 2026-03-14
 * Public: No
 *
 * Description:
 * Initializes the server-side store catalog service for authoritative category hydration and pricing.
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(StoreCatalogServiceBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "StoreCatalogServiceBaseClass"],
    ["#create", compileFinal {
        _self set ["catalogCache", createHashMap];
        ["INFO", "Store catalog service initialized!"] call EFUNC(common,log);
    }],
    ["formatCurrency", compileFinal {
        params [["_amount", 0, [0]]];

        format ["$%1", [_amount max 0] call EFUNC(common,formatNumber)]
    }],
    ["isVisibleConfig", compileFinal {
        params [["_cfg", configNull, [configNull]]];

        isClass _cfg
            && { getNumber (_cfg >> "scope") >= 2 }
            && { (getText (_cfg >> "displayName")) isNotEqualTo "" }
    }],
    ["buildDescription", compileFinal {
        params [["_cfg", configNull, [configNull]], ["_fallback", "", [""]]];

        private _description = getText (_cfg >> "descriptionShort");
        if (_description isEqualTo "") then { _description = _fallback; };

        _description
    }],
    ["normalizeCategoryKey", compileFinal {
        params [["_category", "", [""]]];

        private _categoryKey = toLowerANSI _category;
        if (_categoryKey isEqualTo "items") exitWith { "misc" };

        _categoryKey
    }],
    ["calculateCatalogPriceValue", compileFinal {
        params [
            ["_cfg", configNull, [configNull]],
            ["_isVehicle", false, [false]]
        ];

        if (isNull _cfg) exitWith { 50 };

        private _mass = 0;
        private _priceValue = 0;

        if (_isVehicle) then {
            _priceValue = getNumber (_cfg >> "cost");
        } else {
            private _weaponType = getNumber (_cfg >> "type");
            if (_weaponType in [1, 2, 4]) then { _mass = getNumber (_cfg >> "WeaponSlotsInfo" >> "mass"); };
            if (_mass <= 0) then { _mass = getNumber (_cfg >> "ItemInfo" >> "mass"); };
            if (_mass <= 0) then { _mass = getNumber (_cfg >> "mass"); };

            _priceValue = ceil ((_mass max 0) * 7.5);
        };

        _priceValue max 50
    }],
    ["buildCatalogItem", compileFinal {
        params [
            ["_cfg", configNull, [configNull]],
            ["_typeLabel", "", [""]],
            ["_fallbackDescription", "", [""]],
            ["_imageField", "picture", [""]],
            ["_isVehicle", false, [false]]
        ];

        if (isNull _cfg) exitWith { createHashMap };

        private _className = configName _cfg;
        private _displayName = getText (_cfg >> "displayName");
        private _picture = getText (_cfg >> _imageField);
        if (_picture isEqualTo "" && { _imageField isNotEqualTo "picture" }) then {
            _picture = getText (_cfg >> "picture");
        };

        private _priceValue = _self call ["calculateCatalogPriceValue", [_cfg, _isVehicle]];

        createHashMapFromArray [
            ["className", _className],
            ["code", _className],
            ["name", _displayName],
            ["description", _self call ["buildDescription", [_cfg, _fallbackDescription]]],
            ["price", _self call ["formatCurrency", [_priceValue]]],
            ["priceValue", _priceValue],
            ["image", _picture],
            ["type", _typeLabel]
        ]
    }],
    ["appendCfgWeaponsByItemInfoType", compileFinal {
        params [["_items", [], [[]]], ["_itemInfoType", -1, [0]], ["_typeLabel", "", [""]], ["_fallbackDescription", "", [""]]];

        {
            private _cfg = _x;
            if (
                _self call ["isVisibleConfig", [_cfg]]
                && { getNumber (_cfg >> "ItemInfo" >> "type") isEqualTo _itemInfoType }
            ) then {
                _items pushBack (_self call ["buildCatalogItem", [_cfg, _typeLabel, _fallbackDescription]]);
            };
        } forEach ("true" configClasses (configFile >> "CfgWeapons"));

        _items
    }],
    ["appendCfgWeaponsByType", compileFinal {
        params [["_items", [], [[]]], ["_weaponType", -1, [0]], ["_typeLabel", "", [""]], ["_fallbackDescription", "", [""]]];

        {
            private _cfg = _x;
            if (
                _self call ["isVisibleConfig", [_cfg]]
                && { getNumber (_cfg >> "type") isEqualTo _weaponType }
            ) then {
                _items pushBack (_self call ["buildCatalogItem", [_cfg, _typeLabel, _fallbackDescription]]);
            };
        } forEach ("true" configClasses (configFile >> "CfgWeapons"));

        _items
    }],
    ["isAceClassName", compileFinal {
        params [["_cfg", configNull, [configNull]]];

        ((toLowerANSI (configName _cfg)) select [0, 4]) isEqualTo "ace_"
    }],
    ["isAttachmentConfig", compileFinal {
        params [["_cfg", configNull, [configNull]]];

        if !(_self call ["isVisibleConfig", [_cfg]]) exitWith { false };
        if (_self call ["isAceClassName", [_cfg]]) exitWith { false };

        private _className = configName _cfg;
        private _itemType = [_className] call BIS_fnc_itemType;
        private _group = toLowerANSI (_itemType param [0, ""]);
        private _kind = toLowerANSI (_itemType param [1, ""]);

        (_group find "accessory") >= 0
            || { (_kind find "accessory") >= 0 }
            || { _kind in ["accessorymuzzle", "accessorypointer", "accessorysights", "accessorybipod"] }
    }],
    ["resolveAttachmentTypeLabel", compileFinal {
        params [["_cfg", configNull, [configNull]]];

        private _className = configName _cfg;
        private _itemType = [_className] call BIS_fnc_itemType;
        private _kind = toLowerANSI (_itemType param [1, ""]);

        if ((_kind find "muzzle") >= 0) exitWith { "Muzzle Attachment" };
        if ((_kind find "optic") >= 0 || { (_kind find "sight") >= 0 }) exitWith { "Optic Attachment" };
        if ((_kind find "pointer") >= 0 || { (_kind find "flash") >= 0 } || { (_kind find "light") >= 0 }) exitWith { "Light Attachment" };
        if ((_kind find "bipod") >= 0) exitWith { "Bipod Attachment" };

        "Attachment"
    }],
    ["appendCfgAttachments", compileFinal {
        params [["_items", [], [[]]], ["_fallbackDescription", "", [""]]];

        {
            private _cfg = _x;
            if (_self call ["isAttachmentConfig", [_cfg]]) then {
                private _typeLabel = _self call ["resolveAttachmentTypeLabel", [_cfg]];
                _items pushBack (_self call ["buildCatalogItem", [_cfg, _typeLabel, _fallbackDescription]]);
            };
        } forEach ("true" configClasses (configFile >> "CfgWeapons"));

        _items
    }],
    ["appendCfgVehiclesByKind", compileFinal {
        params [["_items", [], [[]]], ["_baseClass", "", [""]], ["_typeLabel", "", [""]], ["_fallbackDescription", "", [""]]];

        {
            private _cfg = _x;
            private _className = configName _cfg;
            if (
                _self call ["isVisibleConfig", [_cfg]]
                && { getNumber (_cfg >> "isBackpack") isEqualTo 0 }
                && { !(_className isKindOf ["CAManBase", configFile >> "CfgVehicles"]) }
                && { !(_className isKindOf ["StaticWeapon", configFile >> "CfgVehicles"]) }
                && { _className isKindOf [_baseClass, configFile >> "CfgVehicles"] }
            ) then {
                _items pushBack (_self call ["buildCatalogItem", [_cfg, _typeLabel, _fallbackDescription, "editorPreview", true]]);
            };
        } forEach ("true" configClasses (configFile >> "CfgVehicles"));

        _items
    }],
    ["isBackpackConfig", compileFinal {
        params [["_cfg", configNull, [configNull]]];

        getNumber (_cfg >> "isBackpack") isEqualTo 1
            || { getNumber (_cfg >> "ItemInfo" >> "type") isEqualTo TYPE_BACKPACK }
    }],
    ["appendCfgBackpacks", compileFinal {
        params [["_items", [], [[]]], ["_typeLabel", "Backpack", [""]], ["_fallbackDescription", "", [""]]];

        {
            private _cfg = _x;
            if (
                _self call ["isVisibleConfig", [_cfg]]
                && { _self call ["isBackpackConfig", [_cfg]] }
            ) then {
                _items pushBack (_self call ["buildCatalogItem", [_cfg, _typeLabel, _fallbackDescription]]);
            };
        } forEach ("true" configClasses (configFile >> "CfgVehicles"));

        _items
    }],
    ["scanCategoryItems", compileFinal {
        params [["_category", "", [""]]];

        private _categoryKey = _self call ["normalizeCategoryKey", [_category]];
        if (_categoryKey isEqualTo "") exitWith { [] };

        private _items = [];

        switch (_categoryKey) do {
            case "uniforms": { _items = _self call ["appendCfgWeaponsByItemInfoType", [_items, TYPE_UNIFORM, "Uniform", "Live uniform entry generated from the game inventory."]]; };
            case "headgear": { _items = _self call ["appendCfgWeaponsByItemInfoType", [_items, TYPE_HEADGEAR, "Headgear", "Live headgear entry generated from the game inventory."]]; };
            case "vests": { _items = _self call ["appendCfgWeaponsByItemInfoType", [_items, TYPE_VEST, "Vest", "Live vest entry generated from the game inventory."]]; };
            case "backpacks": { _items = _self call ["appendCfgBackpacks", [_items, "Backpack", "Live backpack entry generated from the game inventory."]]; };
            case "attachments": {
                _items = _self call ["appendCfgAttachments", [_items, "Live attachment entry generated from the game inventory."]];
            };
            case "facewear": {
                { if (_self call ["isVisibleConfig", [_x]]) then { _items pushBack (_self call ["buildCatalogItem", [_x, "Facewear", "Live facewear entry generated from the game inventory."]]); }; } forEach ("true" configClasses (configFile >> "CfgGlasses"));
            };
            case "ammo": {
                { if (_self call ["isVisibleConfig", [_x]]) then { _items pushBack (_self call ["buildCatalogItem", [_x, "Magazine", "Live ammunition entry generated from the game inventory."]]); }; } forEach ("true" configClasses (configFile >> "CfgMagazines"));
            };
            case "misc": {
                {
                    private _cfg = _x;
                    private _className = configName _cfg;
                    private _itemType = [_className] call BIS_fnc_itemType;
                    private _group = _itemType param [0, ""];
                    private _kind = _itemType param [1, ""];
                    private _weaponType = getNumber (_cfg >> "type");
                    private _isAceClass = _self call ["isAceClassName", [_cfg]];

                    if (
                        _self call ["isVisibleConfig", [_cfg]]
                        && { !(_weaponType in [1, 2, 4]) }
                        && { (_group in ["Item", "Equipment"]) || { _isAceClass } }
                        && { !(_kind in ["Uniform", "Vest", "Headgear"]) }
                        && { !(_self call ["isAttachmentConfig", [_cfg]]) }
                        && { (getNumber (_cfg >> "ItemInfo" >> "type") isNotEqualTo TYPE_BACKPACK) }
                    ) then {
                        private _typeLabel = [_kind, "Item"] select (_kind isEqualTo "");
                        _items pushBack (_self call ["buildCatalogItem", [_cfg, _typeLabel, "Live utility entry generated from the game inventory."]]);
                    };
                } forEach ("true" configClasses (configFile >> "CfgWeapons"));
            };
            case "primary": { _items = _self call ["appendCfgWeaponsByType", [_items, 1, "Primary Weapon", "Live primary weapon entry generated from the game inventory."]]; };
            case "handgun": { _items = _self call ["appendCfgWeaponsByType", [_items, 2, "Handgun", "Live sidearm entry generated from the game inventory."]]; };
            case "secondary": { _items = _self call ["appendCfgWeaponsByType", [_items, 4, "Launcher", "Live launcher entry generated from the game inventory."]]; };
            case "cars": { _items = _self call ["appendCfgVehiclesByKind", [_items, "Car", "Vehicle", "Live wheeled vehicle entry generated from the game inventory."]]; };
            case "armor": { _items = _self call ["appendCfgVehiclesByKind", [_items, "Tank", "Vehicle", "Live armored vehicle entry generated from the game inventory."]]; };
            case "helis": { _items = _self call ["appendCfgVehiclesByKind", [_items, "Helicopter", "Aircraft", "Live helicopter entry generated from the game inventory."]]; };
            case "planes": { _items = _self call ["appendCfgVehiclesByKind", [_items, "Plane", "Aircraft", "Live fixed-wing entry generated from the game inventory."]]; };
            case "naval": { _items = _self call ["appendCfgVehiclesByKind", [_items, "Ship", "Naval", "Live naval vehicle entry generated from the game inventory."]]; };
            case "other": {
                {
                    private _cfg = _x;
                    private _className = configName _cfg;
                    private _isSupportedVehicle = _className isKindOf ["AllVehicles", configFile >> "CfgVehicles"];
                    private _isKnownCategory =
                        _className isKindOf ["Car", configFile >> "CfgVehicles"]
                        || { _className isKindOf ["Tank", configFile >> "CfgVehicles"] }
                        || { _className isKindOf ["Helicopter", configFile >> "CfgVehicles"] }
                        || { _className isKindOf ["Plane", configFile >> "CfgVehicles"] }
                        || { _className isKindOf ["Ship", configFile >> "CfgVehicles"] };

                    if (
                        _self call ["isVisibleConfig", [_cfg]]
                        && { _isSupportedVehicle }
                        && { !_isKnownCategory }
                        && { getNumber (_cfg >> "isBackpack") isEqualTo 0 }
                        && { !(_className isKindOf ["CAManBase", configFile >> "CfgVehicles"]) }
                        && { !(_className isKindOf ["StaticWeapon", configFile >> "CfgVehicles"]) }
                    ) then {
                        _items pushBack (_self call ["buildCatalogItem", [_cfg, "Special Vehicle", "Live specialty vehicle entry generated from the game inventory.", "editorPreview", true]]);
                    };
                } forEach ("true" configClasses (configFile >> "CfgVehicles"));
            };
        };

        private _sortedItems = _items apply { [toLowerANSI (_x getOrDefault ["name", ""]), _x] };
        _sortedItems sort true;
        _sortedItems apply { _x select 1 }
    }],
    ["isVehicleCategory", compileFinal {
        params [["_category", "", [""]]];

        (toLowerANSI _category) in ["cars", "armor", "helis", "planes", "naval", "other"]
    }],
    ["buildPayloadCategory", compileFinal {
        params [["_category", "", [""]]];

        switch (toLowerANSI _category) do {
            case "backpacks": { "backpack" };
            case "attachments": { "attachment" };
            case "ammo": { "magazine" };
            case "primary";
            case "secondary";
            case "handgun": { "weapon" };
            case "cars";
            case "armor";
            case "helis";
            case "planes";
            case "naval";
            case "other": { toLowerANSI _category };
            default { "item" };
        }
    }],
    ["isSupportedCategory", compileFinal {
        params [["_category", "", [""]]];

        (_self call ["normalizeCategoryKey", [_category]]) in ["uniforms", "headgear", "vests", "backpacks", "attachments", "facewear", "ammo", "misc", "primary", "handgun", "secondary", "cars", "armor", "helis", "planes", "naval", "other"]
    }],
    ["buildCategoryItems", compileFinal {
        params [["_category", "", [""]]];

        private _categoryKey = _self call ["normalizeCategoryKey", [_category]];
        if (_categoryKey isEqualTo "") exitWith { [] };

        private _catalogCache = _self getOrDefault ["catalogCache", createHashMap];
        if (_categoryKey in (keys _catalogCache)) exitWith { _catalogCache get _categoryKey };

        private _items = _self call ["scanCategoryItems", [_categoryKey]];
        private _payloadCategory = _self call ["buildPayloadCategory", [_categoryKey]];
        private _entryKind = ["item", "vehicle"] select (_self call ["isVehicleCategory", [_categoryKey]]);

        {
            _x set ["category", _payloadCategory];
            _x set ["entryKind", _entryKind];
        } forEach _items;

        _catalogCache set [_categoryKey, _items];
        _self set ["catalogCache", _catalogCache];

        _items
    }],
    ["buildCategoryResponse", compileFinal {
        params [["_category", "", [""]]];

        private _categoryKey = _self call ["normalizeCategoryKey", [_category]];
        private _response = createHashMapFromArray [["success", false], ["category", _categoryKey], ["items", []], ["message", "No store category was provided."]];

        if (_categoryKey isEqualTo "") exitWith { _response };
        if !(_self call ["isSupportedCategory", [_categoryKey]]) exitWith {
            _response set ["message", format ["Unsupported store category: %1", _categoryKey]];
            _response
        };

        _response set ["success", true];
        _response set ["message", ""];
        _response set ["items", _self call ["buildCategoryItems", [_categoryKey]]];
        _response
    }],
    ["resolveCheckoutCategories", compileFinal {
        params [["_entry", createHashMap, [createHashMap]]];

        private _entryKind = toLowerANSI (_entry getOrDefault ["entryKind", "item"]);
        private _category = toLowerANSI (_entry getOrDefault ["category", ""]);

        if (_entryKind isEqualTo "vehicle") exitWith { ["cars", "armor", "helis", "planes", "naval", "other"] };
        if (_category isEqualTo "weapon") exitWith { ["primary", "handgun", "secondary"] };
        if (_category isEqualTo "backpack") exitWith { ["backpacks"] };
        if (_category isEqualTo "attachment") exitWith { ["attachments"] };
        if (_category isEqualTo "magazine") exitWith { ["ammo"] };

        ["uniforms", "headgear", "vests", "facewear", "misc", "attachments", "backpacks"]
    }],
    ["resolveCheckoutCatalogEntry", compileFinal {
        params [["_entry", createHashMap, [createHashMap]]];

        private _className = toLowerANSI (_entry getOrDefault ["classname", ""]);
        if (_className isEqualTo "") exitWith { createHashMap };

        private _resolved = createHashMap;
        {
            private _catalogEntries = _self call ["buildCategoryItems", [_x]];
            private _match = _catalogEntries select { (toLowerANSI (_x getOrDefault ["className", ""])) isEqualTo _className };

            if (_match isNotEqualTo []) exitWith { _resolved = _match select 0; };
        } forEach (_self call ["resolveCheckoutCategories", [_entry]]);

        _resolved
    }],
    ["buildCheckoutRequest", compileFinal {
        params [["_items", [], [[]]], ["_vehicles", [], [[]]]];

        private _result = createHashMapFromArray [
            ["success", false],
            ["total", 0],
            ["message", "Checkout total must be greater than zero."],
            ["items", []],
            ["vehicles", []]
        ];
        private _total = 0;
        private _message = "";
        private _resolvedItems = [];
        private _resolvedVehicles = [];

        {
            if (_message isEqualTo "") then {
                private _className = _x getOrDefault ["classname", ""];
                private _quantity = floor ((_x getOrDefault ["quantity", 1]) max 0);

                if (_className isEqualTo "" || { _quantity <= 0 }) then {
                    _message = "Checkout contains an invalid item entry.";
                } else {
                    private _catalogEntry = _self call ["resolveCheckoutCatalogEntry", [createHashMapFromArray [["classname", _className], ["category", _x getOrDefault ["category", "item"]], ["entryKind", "item"]]]];

                    if (_catalogEntry isEqualTo createHashMap) then {
                        _message = format ["Unsupported store item: %1", _className];
                    } else {
                        private _priceValue = _catalogEntry getOrDefault ["priceValue", 0];
                        _total = _total + (_priceValue * _quantity);
                        _resolvedItems pushBack (createHashMapFromArray [
                            ["classname", _className],
                            ["category", _catalogEntry getOrDefault ["category", "item"]],
                            ["priceValue", _priceValue],
                            ["quantity", _quantity]
                        ]);
                    };
                };
            };
        } forEach _items;

        {
            if (_message isEqualTo "") then {
                private _className = _x getOrDefault ["classname", ""];
                if (_className isEqualTo "") then {
                    _message = "Checkout contains an invalid vehicle entry.";
                } else {
                    private _catalogEntry = _self call ["resolveCheckoutCatalogEntry", [createHashMapFromArray [["classname", _className], ["category", _x getOrDefault ["category", ""]], ["entryKind", "vehicle"]]]];

                    if (_catalogEntry isEqualTo createHashMap) then {
                        _message = format ["Unsupported store vehicle: %1", _className];
                    } else {
                        private _priceValue = _catalogEntry getOrDefault ["priceValue", 0];
                        _total = _total + _priceValue;
                        _resolvedVehicles pushBack (createHashMapFromArray [
                            ["classname", _className],
                            ["category", _catalogEntry getOrDefault ["category", _x getOrDefault ["category", "other"]]],
                            ["priceValue", _priceValue]
                        ]);
                    };
                };
            };
        } forEach _vehicles;

        if (_message isNotEqualTo "") exitWith {
            _result set ["message", _message];
            _result
        };

        if (_total <= 0) exitWith { _result };

        _result set ["success", true];
        _result set ["total", floor _total];
        _result set ["message", ""];
        _result set ["items", _resolvedItems];
        _result set ["vehicles", _resolvedVehicles];
        _result
    }],
    ["calculateCheckoutTotal", compileFinal {
        params [["_items", [], [[]]], ["_vehicles", [], [[]]]];

        private _checkout = _self call ["buildCheckoutRequest", [_items, _vehicles]];
        createHashMapFromArray [
            ["success", _checkout getOrDefault ["success", false]],
            ["total", _checkout getOrDefault ["total", 0]],
            ["message", _checkout getOrDefault ["message", "Checkout total must be greater than zero."]]
        ]
    }]
];

GVAR(StoreCatalogService) = createHashMapObject [GVAR(StoreCatalogServiceBaseClass)];
GVAR(StoreCatalogService)
