# Forge Server Economy

## Overview
The economy addon contains server-side systems for world economic interactions
that are still implemented in SQF. It owns Arma-world behavior such as active
refueling sessions, medical spawn occupancy, respawn placement, and death
inventory handling.

Current stores cover fuel tracking, medical service behavior, and service
charges such as repairs and rearming.

## Dependencies
- `forge_server_main`
- `forge_server_common` for logging, formatting, and player lookup
- `forge_server_bank` (runtime) for player-funded medical billing
- `forge_server_org` (runtime) for extension-backed organization hot-cache charges
- `forge_client_actor` and `forge_client_notifications` for response RPCs

Note: Bank and Org are runtime-only dependencies (not compile-time requiredAddons). They must be loaded before economy stores initialize.

## Main Components
- `fnc_initFEconomyStore.sqf` tracks active refueling sessions, calculates fuel
  totals, charges the player's organization through `OrgStore`, syncs the org
  patch, and rolls fuel back to the starting level when organization funds
  cannot cover the refuel.
- `fnc_initMEconomyStore.sqf` manages medical spawn occupancy, healing charges,
  respawn placement, death inventory handling, and body-bag transfer. Medical
  charges use player bank/cash first, then organization funds with repayable
  member debt only when the player cannot cover the service.
- `fnc_initSEconomyStore.sqf` handles organization-funded service charges,
  repairs, and rearming. Vehicle services only apply after the organization
  charge succeeds. The
  shared org-charge helper can also record member debt for medical fallback.

## Event Surface
The addon registers CBA server events for fuel start/tick/stop, direct refuel
service, repair service, player killed, player respawn, and healing. Medical
store initialization runs after post-init to discover configured medical spawn
objects.

Service results emit notifications and syncs through the event bus:
- `notification.requested` - service receipts and failure alerts
- `org.sync.requested` - organization balance updates after service charges
- `bank.account.sync.requested` - player bank/cash balance updates from medical billing

Repair service requests use:

```sqf
[QEGVAR(economy,RepairService), [_target, _unit, _cost]] call CBA_fnc_serverEvent;
```

`_cost` is optional. Passing `-1` uses the configured service repair cost.

Rearm service requests use:

```sqf
[QEGVAR(economy,RearmService), [_target, _unit, _cost]] call CBA_fnc_serverEvent;
```

`_cost` is optional. Passing `-1` uses the configured service rearm cost.
`setVehicleAmmo` has global effects, but only adds ammo to local turrets, so
the ammo reset is broadcast after billing succeeds.

Garage refuel service requests use:

```sqf
[QEGVAR(economy,RefuelService), [_target, _unit]] call CBA_fnc_serverEvent;
```

This fills the selected live vehicle after organization billing succeeds.

## Billing Rules
Economy does not own durable money state. It coordinates Arma-world effects
after the relevant hot-cache charge succeeds.

Fuel and repair services are organization-funded:

1. Resolve the player's organization from actor state.
2. Ensure the player is a member of that organization hot record.
3. Call `OrgStore chargeCheckout` with `source = "org_funds"`,
   `commit = true`, and member service charging enabled.
4. Send the returned organization patch to online members.
5. If the charge fails, do not complete the service. Refueling rolls the target
   back to its starting fuel level; repairs and rearming are not applied.

Direct refuel service requests, such as those from the garage UI, calculate
the missing fuel from `fuelCapacity`, charge the organization, and fill the
vehicle only after the charge succeeds.

Medical services are player-funded first:

1. Load the player's bank hot state.
2. Charge the player's bank balance when it can cover the medical bill.
3. Otherwise charge the player's cash when it can cover the bill.
4. If neither personal balance can cover the bill, charge organization funds
   and record the same amount as a debt on the player's organization credit
   line.
5. If personal billing is unavailable, or both personal and organization funds
   fail, do not complete the heal.

The organization fallback reduces org funds immediately and adds the medical
cost to the player's credit-line balance due. Repayment uses the normal bank
credit-line repayment flow, which moves player bank funds back into the
organization treasury.

This keeps money mutation rules in the extension-backed organization service
and bank service while leaving world interactions in SQF.

## Notes
Fuel, medical, and service world behavior should stay server-authoritative
because it mutates inventory, vehicles, and respawn state. Money mutations
should continue to use extension-backed bank and organization hot state.
