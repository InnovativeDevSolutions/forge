#include "script_component.hpp"

if (isNil QGVAR(OrgRepository)) then { call FUNC(initRepository); true };
if (isNil QGVAR(OrgUIBridge)) then { call FUNC(initUIBridge); true };

[QGVAR(initOrg), {
    GVAR(OrgRepository) call ["init", []];
}] call CFUNC(addEventHandler);

[QGVAR(responseInitOrg), {
    params [["_data", createHashMap, [createHashMap]]];

    GVAR(OrgRepository) call ["markLoaded", []];
}] call CFUNC(addEventHandler);

[QGVAR(responseSyncOrg), {
    params [["_data", createHashMap, [createHashMap]], ["_jip", false, [false]]];

    GVAR(OrgRepository) call ["markLoaded", []];
    GVAR(OrgUIBridge) call ["refreshPortal", []];
}] call CFUNC(addEventHandler);

[QGVAR(responseHydrateOrg), {
    params [["_payload", createHashMap, [createHashMap]], ["_bridgeEvent", "org::sync", [""]]];

    GVAR(OrgUIBridge) call ["handleHydrateResponse", [_payload, _bridgeEvent]];
}] call CFUNC(addEventHandler);

[QGVAR(responseCreateOrg), {
    params [["_payload", createHashMap, [createHashMap]]];

    GVAR(OrgUIBridge) call ["handleCreateResponse", [_payload]];
}] call CFUNC(addEventHandler);

[QGVAR(responseDisbandOrg), {
    params [["_payload", createHashMap, [createHashMap]]];

    GVAR(OrgUIBridge) call ["handleDisbandResponse", [_payload]];
}] call CFUNC(addEventHandler);

[QGVAR(responseLeaveOrg), {
    params [["_payload", createHashMap, [createHashMap]]];

    GVAR(OrgUIBridge) call ["handleLeaveResponse", [_payload]];
}] call CFUNC(addEventHandler);

[QGVAR(responseCreditLine), {
    params [["_payload", createHashMap, [createHashMap]]];

    GVAR(OrgUIBridge) call ["handleCreditLineResponse", [_payload]];
}] call CFUNC(addEventHandler);

[QGVAR(responseTreasuryAction), {
    params [["_payload", createHashMap, [createHashMap]]];

    GVAR(OrgUIBridge) call ["handleTreasuryResponse", [_payload]];
}] call CFUNC(addEventHandler);

[QGVAR(responseInviteOrg), {
    params [["_payload", createHashMap, [createHashMap]]];

    GVAR(OrgUIBridge) call ["handleInviteResponse", [_payload]];
}] call CFUNC(addEventHandler);

[QGVAR(responseInviteDecision), {
    params [["_payload", createHashMap, [createHashMap]]];

    GVAR(OrgUIBridge) call ["handleInviteDecisionResponse", [_payload]];
}] call CFUNC(addEventHandler);

[{
    EGVAR(actor,ActorRepository) get "isLoaded";
}, {
    [QGVAR(initOrg), []] call CFUNC(localEvent);
}] call CFUNC(waitUntilAndExecute);
