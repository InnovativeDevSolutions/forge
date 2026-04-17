#include "..\script_component.hpp"

/*
 * File: fnc_initStoreStore.sqf
 * Author: IDSolutions
 * Date: 2026-03-12
 * Last Update: 2026-04-04
 * Public: No
 *
 * Description:
 * Initializes the server-side store checkout flow.
 */

if (isNil QGVAR(StoreCatalogService)) then { call FUNC(initCatalogService); };

#pragma hemtt ignore_variables ["_self"]
GVAR(StoreBaseStore) = compileFinal createHashMapFromArray [
    ["#type", "StoreBaseStore"],
    ["#create", compileFinal {
        ["INFO", "Store checkout service initialized!"] call EFUNC(common,log);
    }],
    ["buildHydratePayload", compileFinal {
        params [["_uid", "", [""]]];

        if (_uid isEqualTo "") exitWith { createHashMap };

        private _player = [_uid] call EFUNC(common,getPlayer);
        if (isNull _player) exitWith { createHashMap };

        private _budget = 50000;
        private _creditLine = 0;
        private _creditLineDue = 0;
        private _cashBalance = 0;
        private _bankBalance = 0;
        private _orgFunds = 0;
        private _orgName = "";
        private _orgOwnerUid = "";
        private _orgCreditLines = createHashMap;
        private _playerVar = toLowerANSI (vehicleVarName _player);
        private _isOrgLeader = false;
        private _isDefaultOrg = false;
        private _isDefaultOrgCeo = false;

        private _bankAccount = EGVAR(bank,BankStore) call ["get", [_uid, ""]];
        if (_bankAccount isEqualTo createHashMap) then {
            _bankAccount = EGVAR(bank,BankStore) call ["init", [_uid]];
        };
        if (_bankAccount isNotEqualTo createHashMap) then {
            _cashBalance = _bankAccount getOrDefault ["cash", 0];
            _bankBalance = _bankAccount getOrDefault ["bank", 0];
        };

        private _orgId = EGVAR(actor,ActorStore) call ["getOrganization", [_uid]];
        private _org = EGVAR(org,OrgStore) call ["loadById", [_orgId]];
        if (_org isEqualTo createHashMap) then {
            _org = EGVAR(org,OrgStore) call ["loadById", ["default"]];
            _orgId = _org getOrDefault ["id", "default"];
        };

        if (_org isNotEqualTo createHashMap) then {
            _orgName = _org getOrDefault ["name", ""];
            _orgOwnerUid = _org getOrDefault ["owner", ""];
            _orgFunds = _org getOrDefault ["funds", 0];
            _orgCreditLines = _org getOrDefault ["credit_lines", createHashMap];
            _isDefaultOrg = (_orgId isEqualTo "default") || { toLowerANSI _orgOwnerUid isEqualTo "server" };
            _isOrgLeader = _orgOwnerUid isEqualTo _uid;
            _isDefaultOrgCeo = _isDefaultOrg && { _playerVar isEqualTo "ceo" };
        };

        if (_orgCreditLines isEqualType createHashMap) then {
            private _playerCreditLine = _orgCreditLines getOrDefault [_uid, createHashMap];
            if (_playerCreditLine isEqualType createHashMap) then {
                _creditLine = _playerCreditLine getOrDefault [
                    "available_amount",
                    _playerCreditLine getOrDefault ["amount", 0]
                ];
                _creditLineDue = _playerCreditLine getOrDefault ["amount_due", 0];
            };
        };

        private _canUseOrgFunds = _isOrgLeader || _isDefaultOrgCeo;
        private _orgFundsEnabled = _canUseOrgFunds && { _orgFunds > 0 };
        private _paymentSources = [
            createHashMapFromArray [
                ["id", "cash"],
                ["label", "Cash"],
                ["balance", _cashBalance],
                ["enabled", _cashBalance > 0],
                ["detail", "Use on-hand cash carried by the player."]
            ],
            createHashMapFromArray [
                ["id", "bank"],
                ["label", "Bank"],
                ["balance", _bankBalance],
                ["enabled", _bankBalance > 0],
                ["detail", "Charge the player bank account."]
            ],
            createHashMapFromArray [
                ["id", "org_funds"],
                ["label", "Org Funds"],
                ["balance", _orgFunds],
                ["enabled", _orgFundsEnabled],
                ["detail", [
                    "Only organization leaders or the default-org CEO can use treasury funds.",
                    [
                        "Charge organization treasury funds.",
                        "No organization funds are currently available."
                    ] select _orgFundsEnabled
                ] select _canUseOrgFunds]
            ],
            createHashMapFromArray [
                ["id", "credit_line"],
                ["label", "Credit Line"],
                ["balance", _creditLine],
                ["enabled", _creditLine > 0],
                ["detail", [
                    "No approved credit line is assigned to this member.",
                    format [
                        "Use the approved procurement credit line. Outstanding due: $%1.",
                        [_creditLineDue] call EFUNC(common,formatNumber)
                    ]
                ] select (_creditLine > 0)]
            ]
        ];

        createHashMapFromArray [
            ["session", createHashMapFromArray [
                ["actorName", name _player],
                ["actorUid", _uid],
                ["approval", "Field Access"],
                ["orgId", _orgId],
                ["orgName", _orgName],
                ["orgLeader", _isOrgLeader],
                ["defaultOrgCeo", _isDefaultOrgCeo],
                ["canUseOrgFunds", _canUseOrgFunds]
            ]],
            ["storeConfig", createHashMapFromArray [
                ["budget", _budget],
                ["creditLine", _creditLine],
                ["availability", "In-Stock"],
                ["moduleState", "Preview"],
                ["paymentSources", _paymentSources],
                ["defaultPaymentSource", "cash"]
            ]],
            ["cartItems", []]
        ]
    }],
    ["buildResult", compileFinal {
        params [["_message", "Checkout failed.", [""]], ["_paymentMethod", "cash", [""]]];

        createHashMapFromArray [
            ["success", false],
            ["message", _message],
            ["paymentMethod", _paymentMethod],
            ["chargedTotal", 0],
            ["lockerGranted", []],
            ["vehicleGranted", []],
            ["bankPatch", createHashMap],
            ["orgPatch", createHashMap],
            ["orgTargetUids", []],
            ["persistenceSucceeded", false],
            ["persistenceFailures", []],
            ["persistenceMessage", ""]
        ]
    }],
    ["formatCurrency", compileFinal {
        params [["_amount", 0, [0]]];

        format ["$%1", [_amount max 0] call EFUNC(common,formatNumber)]
    }],
    ["callCheckoutBackendEnvelope", compileFinal {
        params [["_context", createHashMap, [createHashMap]]];

        private _envelope = createHashMapFromArray [["data", createHashMap], ["error", ""]];
        if (_context isEqualTo createHashMap) exitWith {
            _envelope set ["error", "Checkout request was invalid."];
            _envelope
        };

        ["store:checkout", [toJSON _context]] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        if !(_isSuccess) exitWith {
            _envelope set ["error", "Store backend call failed."];
            _envelope
        };
        if !(_result isEqualType "") exitWith {
            _envelope set ["error", "Store backend returned an invalid response."];
            _envelope
        };
        if ((_result find "Error:") == 0) exitWith {
            ["ERROR", format ["Store extension checkout failed: %1", _result]] call EFUNC(common,log);
            _envelope set ["error", _result select [7]];
            _envelope
        };

        private _data = fromJSON _result;
        if !(_data isEqualType createHashMap) exitWith {
            _envelope set ["error", "Store backend returned unreadable JSON."];
            _envelope
        };

        _envelope set ["data", _data];
        _envelope
    }],
    ["buildCheckoutContext", compileFinal {
        params [
            ["_uid", "", [""]],
            ["_player", objNull, [objNull]],
            ["_paymentMethod", "cash", [""]],
            ["_items", [], [[]]],
            ["_vehicles", [], [[]]]
        ];

        if (_uid isEqualTo "" || { isNull _player }) exitWith { createHashMap };

        private _orgID = EGVAR(org,OrgStore) call ["resolveOrgIdForUid", [_uid]];
        private _requesterIsDefaultOrgCeo = (
            _orgID isEqualTo "default"
            && { toLowerANSI (vehicleVarName _player) isEqualTo "ceo" }
        );

        createHashMapFromArray [
            ["requesterUid", _uid],
            ["requesterName", name _player],
            ["orgId", _orgID],
            ["requesterIsDefaultOrgCeo", _requesterIsDefaultOrgCeo],
            ["paymentMethod", toLowerANSI _paymentMethod],
            ["items", _items],
            ["vehicles", _vehicles]
        ]
    }],
    ["syncCheckoutResult", compileFinal {
        params [["_player", objNull, [objNull]], ["_result", createHashMap, [createHashMap]]];

        if (isNull _player || { _result isEqualTo createHashMap }) exitWith { false };

        private _lockerPatch = _result getOrDefault ["lockerPatch", createHashMap];
        private _vaPatch = _result getOrDefault ["vaPatch", createHashMap];
        private _vgPatch = _result getOrDefault ["vgaragePatch", createHashMap];
        private _bankPatch = _result getOrDefault ["bankPatch", createHashMap];
        private _orgPatch = _result getOrDefault ["orgPatch", createHashMap];

        if (keys _lockerPatch isNotEqualTo []) then { [CRPC(locker,responseSyncLocker), [_lockerPatch], _player] call CFUNC(targetEvent); };
        if (keys _vaPatch isNotEqualTo []) then { [CRPC(locker,responseSyncVA), [_vaPatch], _player] call CFUNC(targetEvent); };
        if (keys _vgPatch isNotEqualTo []) then { [CRPC(garage,responseSyncVG), [_vgPatch], _player] call CFUNC(targetEvent); };
        if (keys _bankPatch isNotEqualTo []) then { [CRPC(bank,responseSyncBank), [_bankPatch], _player] call CFUNC(targetEvent); };

        if (keys _orgPatch isNotEqualTo []) then {
            {
                private _memberPlayer = [_x] call EFUNC(common,getPlayer);
                if (_memberPlayer isNotEqualTo objNull) then {
                    [CRPC(org,responseSyncOrg), [_orgPatch], _memberPlayer] call CFUNC(targetEvent);
                };
            } forEach (_result getOrDefault ["orgTargetUids", []]);
        };

        true
    }],
    ["persistCheckoutState", compileFinal {
        params [
            ["_uid", "", [""]],
            ["_orgID", "", [""]],
            ["_backendResult", createHashMap, [createHashMap]]
        ];

        private _result = createHashMapFromArray [
            ["success", true],
            ["failures", []],
            ["message", ""]
        ];

        if (_uid isEqualTo "" || { _backendResult isEqualTo createHashMap }) exitWith {
            _result set ["success", false];
            _result set ["failures", ["checkout"]];
            _result set ["message", "Checkout persistence context was invalid."];
            _result
        };

        private _persistenceFailures = [];

        if ((keys (_backendResult getOrDefault ["lockerPatch", createHashMap])) isNotEqualTo []) then {
            if ((EGVAR(locker,LockerStore) call ["save", [_uid]]) isEqualTo createHashMap) then {
                _persistenceFailures pushBack "locker";
            };
        };

        if ((keys (_backendResult getOrDefault ["vaPatch", createHashMap])) isNotEqualTo []) then {
            if ((EGVAR(locker,VAStore) call ["save", [_uid]]) isEqualTo createHashMap) then {
                _persistenceFailures pushBack "virtual_arsenal";
            };
        };

        if ((keys (_backendResult getOrDefault ["vgaragePatch", createHashMap])) isNotEqualTo []) then {
            if ((EGVAR(garage,VGarageStore) call ["save", [_uid]]) isEqualTo createHashMap) then {
                _persistenceFailures pushBack "virtual_garage";
            };
        };

        if ((keys (_backendResult getOrDefault ["bankPatch", createHashMap])) isNotEqualTo []) then {
            if ((EGVAR(bank,BankStore) call ["save", [_uid]]) isEqualTo createHashMap) then {
                _persistenceFailures pushBack "bank";
            };
        };

        if (_orgID isNotEqualTo "" && { (keys (_backendResult getOrDefault ["orgPatch", createHashMap])) isNotEqualTo [] }) then {
            if ((EGVAR(org,OrgStore) call ["saveById", [_orgID]]) isEqualTo createHashMap) then {
                _persistenceFailures pushBack "organization";
            };
        };

        if (_persistenceFailures isNotEqualTo []) then {
            _result set ["success", false];
            _result set ["failures", _persistenceFailures];
            _result set ["message", format [
                "Checkout completed, but durable save failed for: %1.",
                _persistenceFailures joinString ", "
            ]];
        };

        _result
    }],
    ["checkout", compileFinal {
        params [["_uid", "", [""]], ["_player", objNull, [objNull]], ["_payloadJson", "", [""]]];

        private _result = _self call ["buildResult", ["Checkout failed.", "cash"]];
        private _payload = fromJSON _payloadJson;
        if !(_payload isEqualType createHashMap) exitWith {
            _result set ["message", "Checkout request payload is invalid."];
            _result
        };

        private _paymentMethod = toLowerANSI (_payload getOrDefault ["paymentMethod", "cash"]);
        private _items = _payload getOrDefault ["items", []];
        private _vehicles = _payload getOrDefault ["vehicles", []];

        if (isNil QGVAR(StoreCatalogService)) exitWith {
            _result set ["message", "Store catalog service is unavailable."];
            _result
        };

        private _checkoutRequest = GVAR(StoreCatalogService) call ["buildCheckoutRequest", [_items, _vehicles]];
        private _totalPrice = _checkoutRequest getOrDefault ["total", 0];

        _result set ["paymentMethod", _paymentMethod];
        _result set ["chargedTotal", _totalPrice];

        if (_items isEqualTo [] && { _vehicles isEqualTo [] }) exitWith {
            _result set ["message", "Add at least one item before checkout."];
            _result
        };

        if !(_checkoutRequest getOrDefault ["success", false]) exitWith {
            _result set ["message", _checkoutRequest getOrDefault ["message", "Checkout total must be greater than zero."]];
            _result
        };

        private _checkoutContext = _self call ["buildCheckoutContext", [
            _uid,
            _player,
            _paymentMethod,
            _checkoutRequest getOrDefault ["items", []],
            _checkoutRequest getOrDefault ["vehicles", []]
        ]];
        if (_checkoutContext isEqualTo createHashMap) exitWith {
            _result set ["message", "Checkout request context was invalid."];
            _result
        };

        private _envelope = _self call ["callCheckoutBackendEnvelope", [_checkoutContext]];
        private _backendResult = _envelope getOrDefault ["data", createHashMap];
        if (_backendResult isEqualTo createHashMap) exitWith {
            _result set ["message", _envelope getOrDefault ["error", "Checkout failed."]];
            _result
        };

        _self call ["syncCheckoutResult", [_player, _backendResult]];
        private _persistenceResult = _self call [
            "persistCheckoutState",
            [
                _uid,
                _checkoutContext getOrDefault ["orgId", ""],
                _backendResult
            ]
        ];

        _result set ["success", true];
        _result set ["message", _backendResult getOrDefault ["message", format [
            "Checkout completed. %1 charged, %2 locker grant(s), %3 vehicle unlock(s).",
            _self call ["formatCurrency", [_totalPrice]],
            count (_backendResult getOrDefault ["lockerGranted", []]),
            count (_backendResult getOrDefault ["vehicleGranted", []])
        ]]];
        _result set ["lockerGranted", _backendResult getOrDefault ["lockerGranted", []]];
        _result set ["vehicleGranted", _backendResult getOrDefault ["vehicleGranted", []]];
        _result set ["persistenceSucceeded", _persistenceResult getOrDefault ["success", false]];
        _result set ["persistenceFailures", _persistenceResult getOrDefault ["failures", []]];
        _result set ["persistenceMessage", _persistenceResult getOrDefault ["message", ""]];

        if !(_persistenceResult getOrDefault ["success", false]) then {
            private _warning = _persistenceResult getOrDefault ["message", "Checkout completed with persistence failures."];
            ["ERROR", format ["Store checkout for %1 completed with persistence failures: %2", _uid, (_persistenceResult getOrDefault ["failures", []]) joinString ", "]] call EFUNC(common,log);
            _result set ["message", format ["%1 %2", _result get "message", _warning]];
        };

        _result
    }]
];

GVAR(StoreStore) = createHashMapObject [GVAR(StoreBaseStore)];
GVAR(StoreStore)
