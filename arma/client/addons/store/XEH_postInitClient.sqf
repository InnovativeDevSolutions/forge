#include "script_component.hpp"

if (isNil QGVAR(StoreUIBridge)) then { call FUNC(initUIBridge); };

[QGVAR(responseCategory), {
    params [["_payload", createHashMap, [createHashMap]]];

    GVAR(StoreUIBridge) call ["handleCategoryResponse", [_payload]];
}] call CFUNC(addEventHandler);

[QGVAR(responseHydrateStore), {
    params [["_payload", createHashMap, [createHashMap]], ["_bridgeEvent", "store::hydrate", [""]]];

    GVAR(StoreUIBridge) call ["handleHydrateResponse", [_payload, _bridgeEvent]];
}] call CFUNC(addEventHandler);

[QGVAR(responseCheckout), {
    params [["_payload", createHashMap, [createHashMap]]];

    GVAR(StoreUIBridge) call ["handleCheckoutResponse", [_payload]];
}] call CFUNC(addEventHandler);
