#include "..\script_component.hpp"

/*
 * File: fnc_handleUIEvents.sqf
 * Author: IDSolutions
 * Date: 2026-01-28
 * Last Update: 2026-04-06
 * Public: No
 *
 * Description:
 * Handles the UI events.
 *
 * Arguments:
 * 0: [CONTROL] - The control that triggered the event
 * 1: [BOOL] - Whether the event is from a confirm dialog
 * 2: [STRING] - The message containing the event data
 *
 * Return Value:
 * UI events handled [BOOL]
 *
 * Example:
 * call forge_client_actor_fnc_handleUIEvents;
 */

params ["_control", "_isConfirmDialog", "_message"];

private _alert = fromJSON _message;
private _event = _alert get "event";
private _data = _alert get "data";

diag_log format ["[FORGE:Client:Actor] Handling UI event: %1 with data: %2", _event, _data];

switch (_event) do {
    case "actor::get::actions": { GVAR(ActorRepository) call ["getNearbyActions", [_control]]; };
    case "actor::close::menu": { closeDialog 1; };
    case "actor::open::atm": { [true] spawn EFUNC(bank,openUI); };
    case "actor::open::bank": { [] spawn EFUNC(bank,openUI); };
    case "actor::open::cad": { [] spawn EFUNC(cad,openUI); };
    case "actor::open::device": { hint "Device interaction is not yet implemented."; };
    case "actor::open::garage": { [] spawn EFUNC(garage,openUI); };
    case "actor::open::vgarage": { [] spawn EFUNC(garage,openVG); };
    case "actor::open::org": { [] spawn EFUNC(org,openUI); };
    case "actor::open::vlocker": { [FORGE_Locker_Box, player, false] spawn AFUNC(arsenal,openBox) };
    case "actor::open::phone": { [] spawn EFUNC(phone,openUI); };
    case "actor::open::iplayer": { hint "Player interaction is not yet implemented." };
    case "actor::open::store": { [] spawn EFUNC(store,openUI); };
    default { hint format ["Unhandled UI event: %1", _event]; };
};

if (_event isNotEqualTo "actor::get::actions") then { closeDialog 1; };

true;
