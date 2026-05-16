#include "..\script_component.hpp"

/*
 * File: fnc_initStore.sqf
 * Author: IDSolutions
 * Date: 2025-12-17
 * Last Update: 2026-04-02
 * Public: No
 *
 * Description:
 *     Initializes the bank store for managing player bank accounts.
 *     Bank account truth lives in the extension hot cache; SQF handles
 *     session state, Arma-facing validation, and client messaging.
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(BankBaseStore) = compileFinal createHashMapFromArray [
    ["#base", EGVAR(common,BaseStore)],
    ["#type", "BankBaseStore"],
    ["#create", compileFinal {
        ["INFO", "Bank Store Initialized!"] call EFUNC(common,log);
    }],
    ["normalizeAccount", compileFinal {
        params [["_uid", "", [""]], ["_account", createHashMap, [createHashMap]], ["_playerName", "", [""]]];

        if (_uid isEqualTo "" || { !(_account isEqualType createHashMap) }) exitWith { createHashMap };

        private _finalAccount = GVAR(BankModel) call ["migrate", [+_account]];
        if ((_finalAccount getOrDefault ["uid", ""]) isEqualTo "") then {
            _finalAccount set ["uid", _uid];
        };
        if ((_finalAccount getOrDefault ["name", ""]) isEqualTo "" && { _playerName isNotEqualTo "" }) then {
            _finalAccount set ["name", _playerName];
        };

        _finalAccount
    }],
    ["callHotBank", compileFinal {
        params [["_function", "", [""]], ["_arguments", [], [[]]]];

        private _envelope = _self call ["callHotBankEnvelope", [_function, _arguments]];
        _envelope getOrDefault ["data", createHashMap]
    }],
    ["callHotBankEnvelope", compileFinal {
        params [["_function", "", [""]], ["_arguments", [], [[]]]];

        private _envelope = createHashMapFromArray [["data", createHashMap], ["error", ""]];

        if (_function isEqualTo "") exitWith { _envelope };

        [_function, _arguments] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        if !(_isSuccess) exitWith {
            _envelope set ["error", format ["Bank backend call '%1' failed.", _function]];
            _envelope
        };
        if !(_result isEqualType "") exitWith {
            _envelope set ["error", format ["Bank backend call '%1' returned an invalid response.", _function]];
            _envelope
        };
        if ((_result find "Error:") == 0) exitWith {
            ["ERROR", format ["Bank extension call '%1' failed: %2", _function, _result]] call EFUNC(common,log);
            _envelope set ["error", _result select [7]];
            _envelope
        };

        private _data = fromJSON _result;
        if !(_data isEqualType createHashMap) exitWith {
            _envelope set ["error", format ["Bank backend call '%1' returned unreadable JSON.", _function]];
            _envelope
        };

        _envelope set ["data", _data];
        _envelope
    }],
    ["loadHotBank", compileFinal {
        params [["_uid", "", [""]], ["_initialize", false, [false]], ["_playerName", "", [""]]];

        if (_uid isEqualTo "") exitWith { createHashMap };

        private _command = ["bank:hot:get", "bank:hot:init"] select _initialize;
        private _account = _self call ["callHotBank", [_command, [_uid]]];
        if (_account isEqualTo createHashMap) exitWith { _account };

        _self call ["normalizeAccount", [_uid, _account, _playerName]]
    }],
    ["finalizeMutation", compileFinal {
        params [
            ["_uid", "", [""]],
            ["_result", createHashMap, [createHashMap]],
            ["_save", false, [false]]
        ];

        if (_uid isEqualTo "" || { _result isEqualTo createHashMap }) exitWith { createHashMap };

        private _account = _result getOrDefault ["account", createHashMap];
        private _patch = _result getOrDefault ["patch", createHashMap];

        if !(_patch isEqualType createHashMap) then {
            _patch = createHashMap;
        };

        if (_save && { _account isNotEqualTo createHashMap }) then {
            private _savedAccount = _self call ["callHotBank", ["bank:hot:save", [_uid]]];
            if (_savedAccount isEqualTo createHashMap) exitWith { createHashMap };
            _account = _savedAccount;
        };

        if (_account isNotEqualTo createHashMap) then {
            _self call ["normalizeAccount", [_uid, _account, ""]];
        };

        _patch
    }],
    ["runMutation", compileFinal {
        params [
            ["_uid", "", [""]],
            ["_command", "", [""]],
            ["_arguments", [], [[]]],
            ["_save", false, [false]],
            ["_notification", "", [""]]
        ];

        if (_uid isEqualTo "" || { _command isEqualTo "" }) exitWith { false };

        private _envelope = _self call ["callHotBankEnvelope", [_command, _arguments]];
        private _result = _envelope getOrDefault ["data", createHashMap];
        private _finalPatch = _self call ["finalizeMutation", [_uid, _result, _save]];
        if (_finalPatch isEqualTo createHashMap) exitWith {
            private _message = _envelope getOrDefault ["error", "Bank operation failed."];
            if (_message isNotEqualTo "") then {
                GVAR(BankMessenger) call ["sendAlert", [_uid, "error", _message]];
            };
            false
        };

        GVAR(BankMessenger) call ["sendAccountSync", [_uid, _finalPatch]];
        if (_notification isNotEqualTo "") then {
            GVAR(BankMessenger) call ["sendNotification", [_uid, "info", "Bank", _notification]];
        };

        true
    }],
    ["chargeCheckout", compileFinal {
        params [["_uid", "", [""]], ["_source", "cash", [""]], ["_amount", 0, [0]], ["_commit", false, [false]]];

        private _result = createHashMapFromArray [["success", false], ["message", "Unable to process bank payment."], ["patch", createHashMap]];
        if (_uid isEqualTo "") exitWith { _result };

        private _checkoutContext = GVAR(BankPayloadBuilder) call ["buildCheckoutContext", [_source, _commit]];
        private _envelope = _self call [
            "callHotBankEnvelope",
            [
                "bank:hot:charge_checkout",
                [_uid, str _amount, toJSON _checkoutContext]
            ]
        ];
        private _mutationResult = _envelope getOrDefault ["data", createHashMap];
        private _patch = _self call ["finalizeMutation", [_uid, _mutationResult, false]];
        if (_patch isEqualTo createHashMap) exitWith {
            _result set ["message", _envelope getOrDefault ["error", "Bank checkout payment failed."]];
            _result
        };

        _result set ["success", true];
        _result set ["message", ""];
        _result set ["patch", _patch];
        _result
    }],
    ["repayCreditLine", compileFinal {
        params [["_uid", "", [""]], ["_amount", 0, [0]]];

        if (_uid isEqualTo "" || { _amount <= 0 }) exitWith {
            GVAR(BankMessenger) call ["sendAlert", [_uid, "error", "Enter a valid repayment amount."]];
            false
        };

        private _originalAccount = _self call ["loadHotBank", [_uid, false, ""]];
        if (_originalAccount isEqualTo createHashMap) then {
            _originalAccount = _self call ["loadHotBank", [_uid, true, ""]];
        };
        if (_originalAccount isEqualTo createHashMap) exitWith {
            GVAR(BankMessenger) call ["sendAlert", [_uid, "error", "Bank account could not be loaded."]];
            false
        };

        private _checkoutContext = GVAR(BankPayloadBuilder) call ["buildCheckoutContext", ["bank", false]];
        private _previewEnvelope = _self call [
            "callHotBankEnvelope",
            [
                "bank:hot:charge_checkout",
                [_uid, str _amount, toJSON _checkoutContext]
            ]
        ];
        private _previewResult = _previewEnvelope getOrDefault ["data", createHashMap];
        private _bankPatch = _self call ["finalizeMutation", [_uid, _previewResult, false]];
        if (_bankPatch isEqualTo createHashMap) exitWith {
            GVAR(BankMessenger) call ["sendAlert", [_uid, "error", _previewEnvelope getOrDefault ["error", "Credit repayment could not be funded from the bank account."]]];
            false
        };

        private _nextAccount = _previewResult getOrDefault ["account", createHashMap];
        if (_nextAccount isEqualTo createHashMap) exitWith {
            GVAR(BankMessenger) call ["sendAlert", [_uid, "error", "Bank repayment preview returned an invalid account state."]];
            false
        };

        private _overrideEnvelope = _self call [
            "callHotBankEnvelope",
            ["bank:hot:override", [_uid, _self call ["toJSON", [_nextAccount]]]]
        ];
        if ((_overrideEnvelope getOrDefault ["data", createHashMap]) isEqualTo createHashMap) exitWith {
            GVAR(BankMessenger) call ["sendAlert", [_uid, "error", _overrideEnvelope getOrDefault ["error", "Credit repayment could not reserve bank funds."]]];
            false
        };

        private _orgResult = EGVAR(org,OrgStore) call ["repayCreditLine", [_uid, _amount]];
        if !(_orgResult getOrDefault ["success", false]) exitWith {
            private _rollbackEnvelope = _self call [
                "callHotBankEnvelope",
                ["bank:hot:override", [_uid, _self call ["toJSON", [_originalAccount]]]]
            ];
            if ((_rollbackEnvelope getOrDefault ["data", createHashMap]) isEqualTo createHashMap) then {
                ["ERROR", format ["Failed to roll back bank state for %1 after org credit repayment failure.", _uid]] call EFUNC(common,log);
            };

            GVAR(BankMessenger) call ["sendAlert", [_uid, "error", _orgResult getOrDefault ["message", "Credit repayment failed."]]];
            false
        };

        private _persistenceFailures = [];
        private _savedBank = _self call ["save", [_uid]];
        if (_savedBank isEqualTo createHashMap) then {
            _persistenceFailures pushBack "bank";
        };

        private _orgPersistenceMessage = _orgResult getOrDefault ["persistenceMessage", ""];
        if !(_orgResult getOrDefault ["persisted", false]) then {
            _persistenceFailures pushBack "organization";
        };

        GVAR(BankMessenger) call ["sendAccountSync", [_uid, _bankPatch]];
        GVAR(BankMessenger) call ["sendNotification", [_uid, "info", "Bank", _orgResult getOrDefault ["message", format ["Repaid $%1 toward the organization credit line.", [_amount] call EFUNC(common,formatNumber)]]]];

        private _orgPatch = _orgResult getOrDefault ["patch", createHashMap];
        if (_orgPatch isNotEqualTo createHashMap) then {
            private _memberUids = +(_orgResult getOrDefault ["memberUids", []]);
            if (isNil QEGVAR(common,EventBus)) then {
                {
                    private _memberPlayer = [_x] call EFUNC(common,getPlayer);
                    if (_memberPlayer isNotEqualTo objNull) then {
                        [CRPC(org,responseSyncOrg), [_orgPatch], _memberPlayer] call CFUNC(targetEvent);
                    };
                } forEach _memberUids;
            } else {
                EGVAR(common,EventBus) call ["emit", [
                    "org.sync.requested",
                    createHashMapFromArray [
                        ["memberUids", _memberUids],
                        ["patch", +_orgPatch]
                    ],
                    createHashMapFromArray [["source", "bank"]]
                ]];
            };
        };

        if (_persistenceFailures isNotEqualTo []) then {
            private _warning = format [
                "Credit repayment posted, but durable save failed for: %1.",
                _persistenceFailures joinString ", "
            ];
            if (_orgPersistenceMessage isNotEqualTo "") then {
                _warning = format ["%1 %2", _warning, _orgPersistenceMessage];
            };

            ["ERROR", format ["Credit repayment for %1 completed with persistence failures: %2", _uid, _persistenceFailures joinString ", "]] call EFUNC(common,log);
            GVAR(BankMessenger) call ["sendAlert", [_uid, "warning", _warning]];
        };

        _self call ["hydrateSession", [_uid, "", false]];
        true
    }],
    ["deposit", compileFinal {
        params [["_uid", "", [""]], ["_amount", 0, [0]]];

        _self call [
            "runMutation",
            [
                _uid,
                "bank:hot:deposit",
                [_uid, str _amount, toJSON (GVAR(BankPayloadBuilder) call ["buildOperationContext", [_uid]])],
                false,
                format ["Deposited $%1", [_amount] call EFUNC(common,formatNumber)]
            ]
        ]
    }],
    ["hydrateSession", compileFinal {
        params [["_uid", "", [""]], ["_mode", "", [""]], ["_resetAuthorization", false, [false]]];

        private _payload = GVAR(BankPayloadBuilder) call ["buildHydratePayload", [_uid, _mode, _resetAuthorization]];
        if (_payload isEqualTo createHashMap) exitWith { false };

        private _player = [_uid] call EFUNC(common,getPlayer);
        if (isNull _player) exitWith { false };

        [CRPC(bank,responseHydrateBank), [_payload], _player] call CFUNC(targetEvent);
        true
    }],
    ["init", compileFinal {
        params [["_uid", "", [""]]];

        if (_uid isEqualTo "") exitWith { createHashMap };

        private _player = [_uid] call EFUNC(common,getPlayer);
        private _playerName = if (isNull _player) then { "Unknown" } else { name _player };
        ["bank:exists", [_uid]] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        if !(_isSuccess) exitWith {
            ["ERROR", format ["Failed to check if bank account %1 exists in backend.", _uid]] call EFUNC(common,log);
            GVAR(BankMessenger) call ["sendAlert", [_uid, "error", "Bank backend is unavailable right now."]];
            createHashMap
        };
        if !(_result isEqualType "") exitWith {
            ["ERROR", format ["Bank exists check for %1 returned an invalid response.", _uid]] call EFUNC(common,log);
            GVAR(BankMessenger) call ["sendAlert", [_uid, "error", "Bank backend returned an invalid response."]];
            createHashMap
        };
        if ((_result find "Error:") == 0) exitWith {
            ["ERROR", format ["Bank exists check for %1 failed: %2", _uid, _result]] call EFUNC(common,log);
            GVAR(BankMessenger) call ["sendAlert", [_uid, "error", _result select [7]]];
            createHashMap
        };

        private _finalAccount = createHashMap;
        if (_result isEqualTo "true") then {
            _finalAccount = _self call ["loadHotBank", [_uid, true, _playerName]];
            ["INFO", format ["Found bank account for %1", _uid]] call EFUNC(common,log);
        } else {
            _finalAccount = GVAR(BankModel) call ["fromPlayer", [_player]];
            _finalAccount set ["uid", _uid];
            if ((_finalAccount getOrDefault ["name", ""]) isEqualTo "") then {
                _finalAccount set ["name", _playerName];
            };

            private _json = _self call ["toJSON", [_finalAccount]];
            ["bank:create", [_uid, _json]] call EFUNC(extension,extCall) params ["_createResult", "_createSuccess"];
            if (!_createSuccess) exitWith {
                ["ERROR", format ["Failed to create bank account %1 in backend.", _uid]] call EFUNC(common,log);
                GVAR(BankMessenger) call ["sendAlert", [_uid, "error", "Failed to create bank account in backend."]];
                createHashMap
            };
            if !(_createResult isEqualType "") exitWith {
                ["ERROR", format ["Bank create for %1 returned an invalid response.", _uid]] call EFUNC(common,log);
                GVAR(BankMessenger) call ["sendAlert", [_uid, "error", "Bank backend returned an invalid create response."]];
                createHashMap
            };
            if ((_createResult find "Error:") == 0) exitWith {
                ["ERROR", format ["Bank create for %1 failed: %2", _uid, _createResult]] call EFUNC(common,log);
                GVAR(BankMessenger) call ["sendAlert", [_uid, "error", _createResult select [7]]];
                createHashMap
            };

            _finalAccount = _self call ["loadHotBank", [_uid, true, _playerName]];
            ["INFO", format ["Created new bank account for %1", _uid]] call EFUNC(common,log);
        };

        if (_finalAccount isEqualTo createHashMap) exitWith {
            ["ERROR", format ["Failed to initialize bank hot state for %1.", _uid]] call EFUNC(common,log);
            GVAR(BankMessenger) call ["sendAlert", [_uid, "error", "Bank account hot state could not be initialized."]];
            createHashMap
        };

        _finalAccount = _self call ["normalizeAccount", [_uid, _finalAccount, _playerName]];
        GVAR(BankMessenger) call ["sendAccountSync", [_uid, _finalAccount, CRPC(bank,responseInitBank)]];
        _finalAccount
    }],
    ["get", compileFinal {
        params [["_uid", "", [""]], ["_field", "", [""]]];

        private _account = _self call ["loadHotBank", [_uid, false, ""]];
        if (_account isEqualTo createHashMap) then {
            _account = _self call ["loadHotBank", [_uid, true, ""]];
        };

        if (_field isEqualTo "") exitWith { _account };
        _account getOrDefault [_field, nil]
    }],
    ["set", compileFinal {
        params [["_uid", "", [""]], ["_field", "", [""]], ["_value", nil, [[], "", 0, false, createHashMap]], ["_sync", false, [false]]];

        if (_uid isEqualTo "" || { _field isEqualTo "" }) exitWith { createHashMap };

        _self call ["mset", [_uid, createHashMapFromArray [[_field, _value]], _sync]]
    }],
    ["mset", compileFinal {
        params [["_uid", "", [""]], ["_fieldValuePairs", createHashMap, [createHashMap]], ["_sync", false, [false]]];

        if (_uid isEqualTo "" || { !(_fieldValuePairs isEqualType createHashMap) }) exitWith { createHashMap };

        private _result = _self call ["callHotBank", ["bank:hot:patch", [_uid, toJSON _fieldValuePairs]]];
        _self call ["finalizeMutation", [_uid, _result, _sync]]
    }],
    ["save", compileFinal {
        params [["_uid", "", [""]]];
        if (_uid isEqualTo "") exitWith { createHashMap };

        private _envelope = _self call ["callHotBankEnvelope", ["bank:hot:save", [_uid]]];
        private _account = _envelope getOrDefault ["data", createHashMap];
        if (_account isEqualTo createHashMap) exitWith {
            private _message = _envelope getOrDefault ["error", "Bank save failed."];
            ["ERROR", format ["Failed to save bank account %1: %2", _uid, _message]] call EFUNC(common,log);
            GVAR(BankMessenger) call ["sendAlert", [_uid, "error", _message]];
            createHashMap
        };

        _self call ["normalizeAccount", [_uid, _account, ""]]
    }],
    ["transfer", compileFinal {
        params [["_uid", "", [""]], ["_target", "", [""]], ["_amount", 0, [0]], ["_context", createHashMap, [createHashMap]]];

        private _transferContext = GVAR(BankPayloadBuilder) call ["buildTransferContext", [_uid, _context getOrDefault ["sourceField", "bank"]]];
        private _envelope = _self call [
            "callHotBankEnvelope",
            [
                "bank:hot:transfer",
                [_uid, _target, str _amount, toJSON _transferContext]
            ]
        ];
        private _result = _envelope getOrDefault ["data", createHashMap];
        if (_result isEqualTo createHashMap) exitWith {
            private _message = _envelope getOrDefault ["error", "Bank transfer failed."];
            if (_message isNotEqualTo "") then {
                GVAR(BankMessenger) call ["sendAlert", [_uid, "error", _message]];
            };
            false
        };

        private _sourceAccount = _result getOrDefault ["sourceAccount", createHashMap];
        private _targetAccount = _result getOrDefault ["targetAccount", createHashMap];
        private _finalSourcePatch = _result getOrDefault ["sourcePatch", createHashMap];
        private _finalTargetPatch = _result getOrDefault ["targetPatch", createHashMap];

        if (
            _finalSourcePatch isEqualTo createHashMap
            || { _finalTargetPatch isEqualTo createHashMap }
        ) exitWith {
            private _message = _envelope getOrDefault ["error", "Bank transfer failed."];
            if (_message isNotEqualTo "") then {
                GVAR(BankMessenger) call ["sendAlert", [_uid, "error", _message]];
            };
            false
        };

        if (_sourceAccount isEqualType createHashMap && { _sourceAccount isNotEqualTo createHashMap }) then {
            _self call ["normalizeAccount", [_uid, _sourceAccount, ""]];
        };
        if (_targetAccount isEqualType createHashMap && { _targetAccount isNotEqualTo createHashMap }) then {
            _self call ["normalizeAccount", [_target, _targetAccount, ""]];
        };

        GVAR(BankMessenger) call ["sendAccountSync", [_uid, _finalSourcePatch]];
        GVAR(BankMessenger) call ["sendAccountSync", [_target, _finalTargetPatch]];

        private _contextTargetAccount = _context getOrDefault ["targetAccount", createHashMap];
        private _contextAccount = _context getOrDefault ["account", createHashMap];
        private _targetPlayer = [_target] call EFUNC(common,getPlayer);
        private _targetName = if (isNull _targetPlayer) then { _contextTargetAccount getOrDefault ["name", "Recipient"] } else { name _targetPlayer };
        private _player = [_uid] call EFUNC(common,getPlayer);
        private _playerName = if (isNull _player) then { _contextAccount getOrDefault ["name", "Unknown"] } else { name _player };

        GVAR(BankMessenger) call ["sendNotification", [_uid, "info", "Bank", format ["Transferred $%1 to %2", [_amount] call EFUNC(common,formatNumber), _targetName]]];
        GVAR(BankMessenger) call ["sendNotification", [_target, "info", "Bank", format ["Received $%1 from %2", [_amount] call EFUNC(common,formatNumber), _playerName]]];
        true
    }],
    ["validatePin", compileFinal {
        params [["_uid", "", [""]], ["_pin", "", [""]]];

        if (_uid isEqualTo "") exitWith { false };

        private _enteredPin = _pin;
        if !(_enteredPin isEqualType "") then {
            _enteredPin = str _enteredPin;
        };

        private _envelope = _self call [
            "callHotBankEnvelope",
            [
                "bank:hot:validate_pin",
                [_uid, _enteredPin, toJSON (GVAR(BankPayloadBuilder) call ["buildOperationContext", [_uid, "atm"]])]
            ]
        ];

        private _message = _envelope getOrDefault ["error", ""];
        if (_message isNotEqualTo "") then {
            GVAR(BankMessenger) call ["sendAlert", [_uid, "error", _message]];
            false
        } else {
            true
        }
    }],
    ["changePin", compileFinal {
        params [["_uid", "", [""]], ["_currentPin", "", [""]], ["_newPin", "", [""]]];

        if (_uid isEqualTo "") exitWith { false };

        private _current = _currentPin;
        private _next = _newPin;
        if !(_current isEqualType "") then { _current = str _current; };
        if !(_next isEqualType "") then { _next = str _next; };

        private _changed = _self call [
            "runMutation",
            [
                _uid,
                "bank:hot:change_pin",
                [_uid, _current, _next, toJSON (GVAR(BankPayloadBuilder) call ["buildOperationContext", [_uid]])],
                true,
                ""
            ]
        ];

        if (_changed) then {
            GVAR(BankMessenger) call ["sendAlert", [_uid, "success", "Bank PIN updated."]];
            _self call ["hydrateSession", [_uid, "", false]];
        };

        _changed
    }],
    ["withdraw", compileFinal {
        params [["_uid", "", [""]], ["_amount", 0, [0]]];

        _self call [
            "runMutation",
            [
                _uid,
                "bank:hot:withdraw",
                [_uid, str _amount, toJSON (GVAR(BankPayloadBuilder) call ["buildOperationContext", [_uid]])],
                false,
                format ["Withdrew $%1", [_amount] call EFUNC(common,formatNumber)]
            ]
        ]
    }],
    ["depositEarnings", compileFinal {
        params [["_uid", "", [""]], ["_amount", 0, [0]]];

        _self call [
            "runMutation",
            [
                _uid,
                "bank:hot:deposit_earnings",
                [_uid, str _amount, toJSON (GVAR(BankPayloadBuilder) call ["buildOperationContext", [_uid]])],
                false,
                format ["Deposited $%1 from earnings", [_amount] call EFUNC(common,formatNumber)]
            ]
        ]
    }]
];

GVAR(BankStore) = createHashMapObject [GVAR(BankBaseStore)];
GVAR(BankStore)
