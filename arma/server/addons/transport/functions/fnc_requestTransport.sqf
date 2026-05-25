#include "..\script_component.hpp"

/*
 * File: fnc_requestTransport.sqf
 * Author: IDSolutions
 * Date: 2026-05-25
 * Public: No
 *
 * Description:
 * Requests a paid transport transfer for a player and nearby cargo.
 *
 * Arguments:
 * 0: Player unit <OBJECT>
 * 1: Origin node <OBJECT>
 * 2: Destination node <OBJECT>
 * 3: Options <HASHMAP> (optional)
 *
 * Return Value:
 * Result [HASHMAP]
 *
 * Example:
 * [player, transport, transport_1] call forge_server_transport_fnc_requestTransport
 */

params [
    ["_unit", objNull, [objNull]],
    ["_fromNode", objNull, [objNull]],
    ["_toNode", objNull, [objNull]],
    ["_options", createHashMap, [createHashMap]]
];

if (isNil QGVAR(TransportService)) then { call FUNC(initTransportService); };
GVAR(TransportService) call ["requestTransport", [_unit, _fromNode, _toNode, _options]]
