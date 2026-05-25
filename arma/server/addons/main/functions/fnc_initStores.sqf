#include "..\script_component.hpp"

/*
 * Author: J.Schmidt
 * Initializes all stores in the correct order.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call forge_server_main_fnc_initStores;
 *
 * Public: No
 */

// Base
if (isNil QEGVAR(common,BaseStore)) then { call EFUNC(common,baseStore); true };
if (isNil QEGVAR(common,EventBus)) then { call EFUNC(common,eventBus); true };

// Actor
if (isNil QEGVAR(actor,ActorStore)) then { call EFUNC(actor,initActorStore); true };

// Bank
if (isNil QEGVAR(bank,BankSessionManager)) then { call EFUNC(bank,initSessionManager); true };
if (isNil QEGVAR(bank,BankMessenger)) then { call EFUNC(bank,initMessenger); true };
if (isNil QEGVAR(bank,BankModel)) then { call EFUNC(bank,initModel); true };
if (isNil QEGVAR(bank,BankPayloadBuilder)) then { call EFUNC(bank,initPayloadBuilder); true };
if (isNil QEGVAR(bank,BankStore)) then { call EFUNC(bank,initBankStore); true };

// Garage
if (isNil QEGVAR(garage,GarageStore)) then { call EFUNC(garage,initGarageStore); true };

// VGarage
if (isNil QEGVAR(garage,VGarageStore)) then { call EFUNC(garage,initVGStore); true };

// Locker
if (isNil QEGVAR(locker,LockerStore)) then { call EFUNC(locker,initLockerStore); true };

// VArsenal
if (isNil QEGVAR(locker,VAStore)) then { call EFUNC(locker,initVAStore); true };

// Org
if (isNil QEGVAR(org,OrgPayloadBuilder)) then { call EFUNC(org,initPayloadBuilder); true };
if (isNil QEGVAR(org,OrgStore)) then { call EFUNC(org,initOrgStore); true };

// Store
if (isNil QEGVAR(store,StorefrontStore)) then { call EFUNC(store,initStorefrontStore); true };

// Validation Harness
if (isNil QGVAR(ValidationHarness)) then { call FUNC(initValidationHarness); true };
