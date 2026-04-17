#include "script_component.hpp"

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

// private _category = [QUOTE(MOD_NAME), LLSTRING(displayName)];

[QGVAR(requestCategory), {
    params [["_uid", "", [""]], ["_category", "", [""]]];

    if (_uid isEqualTo "" || { _category isEqualTo "" }) exitWith {
        diag_log "[FORGE:Server:Store] Invalid category request payload."
    };

    private _player = [_uid] call EFUNC(common,getPlayer);
    if (_player isEqualTo objNull) exitWith {};

    if (isNil QGVAR(StoreCatalogService)) exitWith {
        diag_log "[FORGE:Server:Store] Store catalog service is unavailable."
    };

    private _result = GVAR(StoreCatalogService) call ["buildCategoryResponse", [_category]];
    [CRPC(store,responseCategory), [_result], _player] call CFUNC(targetEvent);
}] call CFUNC(addEventHandler);

[QGVAR(requestHydrateStore), {
    params [["_uid", "", [""]], ["_bridgeEvent", "store::hydrate", [""]]];

    if (_uid isEqualTo "") exitWith {
        diag_log "[FORGE:Server:Store] Invalid hydrate request payload."
    };

    if !(_bridgeEvent in ["store::hydrate", "store::config::hydrate"]) then {
        _bridgeEvent = "store::hydrate";
    };

    private _player = [_uid] call EFUNC(common,getPlayer);
    if (_player isEqualTo objNull) exitWith {};

    private _payload = GVAR(StorefrontStore) call ["buildHydratePayload", [_uid]];
    if (_payload isEqualTo createHashMap) exitWith {};

    [CRPC(store,responseHydrateStore), [_payload, _bridgeEvent], _player] call CFUNC(targetEvent);
}] call CFUNC(addEventHandler);

[QGVAR(requestCheckout), {
    params [["_uid", "", [""]], ["_payloadJson", "", [""]]];

    if (_uid isEqualTo "" || { _payloadJson isEqualTo "" }) exitWith {
        diag_log "[FORGE:Server:Store] Invalid checkout request payload."
    };

    private _player = [_uid] call EFUNC(common,getPlayer);
    if (_player isEqualTo objNull) exitWith {};

    private _result = GVAR(StorefrontStore) call ["checkout", [_uid, _player, _payloadJson]];
    [CRPC(store,responseCheckout), [_result], _player] call CFUNC(targetEvent);
}] call CFUNC(addEventHandler);
