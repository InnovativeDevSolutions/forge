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
if (isNil QEGVAR(common,BaseStore)) then { call EFUNC(common,baseStore); };
if (isNil QEGVAR(common,EventBus)) then { call EFUNC(common,eventBus); };

// Actor
if (isNil QEGVAR(actor,ActorStore)) then { call EFUNC(actor,initActorStore); };

// Bank
if (isNil QEGVAR(bank,BankSessionManager)) then { call EFUNC(bank,initSessionManager); };
if (isNil QEGVAR(bank,BankMessenger)) then { call EFUNC(bank,initMessenger); };
if (isNil QEGVAR(bank,BankModel)) then { call EFUNC(bank,initModel); };
if (isNil QEGVAR(bank,BankPayloadBuilder)) then { call EFUNC(bank,initPayloadBuilder); };
if (isNil QEGVAR(bank,BankStore)) then { call EFUNC(bank,initStore); };

// Garage
if (isNil QEGVAR(garage,GarageStore)) then { call EFUNC(garage,initGarageStore); };

// VGarage
if (isNil QEGVAR(garage,VGarageStore)) then { call EFUNC(garage,initVGStore); };

// Locker
if (isNil QEGVAR(locker,LockerStore)) then { call EFUNC(locker,initLockerStore); };

// VArsenal
if (isNil QEGVAR(locker,VAStore)) then { call EFUNC(locker,initVAStore); };

// Org
if (isNil QEGVAR(org,OrgPayloadBuilder)) then { call EFUNC(org,initPayloadBuilder); };
if (isNil QEGVAR(org,OrgStore)) then { call EFUNC(org,initOrgStore); };

// Store
if (isNil QEGVAR(store,StorefrontStore)) then { call EFUNC(store,initStorefrontStore); };

// Validation Harness
if (isNil QGVAR(ValidationHarness)) then { call FUNC(initValidationHarness); };
