# Economy Usage Guide

The economy server addon owns Arma-world service behavior for fuel, medical,
and repair interactions. It does not own money state. Money mutations go
through extension-backed bank and organization hot state before the world
effect is applied.

## Dependencies

- `forge_server_common` for logging, formatting, and player lookup.
- `forge_server_bank` for personal medical billing.
- `forge_server_org` for organization-funded services and medical fallback
  debt.
- `forge_client_actor` and `forge_client_notifications` for targeted client
  responses.

## Fuel

Fuel is organization-funded.

When refueling stops, `fnc_initFEconomyStore.sqf` calculates the fuel delta and
cost, charges the player's organization through `OrgStore chargeCheckout`, and
syncs the organization patch to online members. If organization funds cannot
cover the refuel, the vehicle is rolled back to the fuel level it had when the
session started.

Garage UI refuel requests use the server `RefuelService` event. The fuel store
calculates missing fuel from the vehicle config `fuelCapacity`, charges the
player's organization, and fills the vehicle only after the organization charge
succeeds.

The refuel price per liter is controlled by `fuelCost`. The mission setup UI
can override it at startup; otherwise a mission `Params` entry named
`fuelCost` or `CfgServicePricing >> fuelCost` is used.

## Repair

Repair is organization-funded.

Use the repair service event:

```sqf
[QEGVAR(economy,RepairService), [_target, _unit, _cost]] call CBA_fnc_serverEvent;
```

`_cost` is optional. Passing `-1` uses the configured service repair cost.
The target is only repaired after the organization charge succeeds.

The client garage UI forwards selected nearby vehicle repair requests through
the same event.

The default repair charge is controlled by `serviceRepairCost`. A direct
service event can still pass a concrete `_cost` to override that request.

## Rearm

Rearm is organization-funded.

Use the rearm service event:

```sqf
[QEGVAR(economy,RearmService), [_target, _unit, _cost]] call CBA_fnc_serverEvent;
```

`_cost` is optional. Passing `-1` uses the configured service rearm cost.
The target is only rearmed after the organization charge succeeds.
`setVehicleAmmo` has global effects, but the ammo is only added to local
turrets, so the service broadcasts the ammo reset after billing succeeds.

The client garage UI forwards selected nearby vehicle rearm requests through
the same event.

The default rearm charge is controlled by `serviceRearmCost`. A direct service
event can still pass a concrete `_cost` to override that request.

## Medical

Medical is player-funded first.

When a heal is requested, `fnc_initMEconomyStore.sqf` uses this billing order:

1. Charge the player's bank balance when it can cover the medical fee.
2. Otherwise charge the player's cash when it can cover the fee.
3. If neither personal balance can cover the fee, charge organization funds.
4. When organization funds cover the fallback charge, record the same amount as
   debt on the player's organization credit line.

The heal only completes after one of those charges succeeds. If personal
billing is unavailable, the heal does not fall back to organization funds
because the server cannot verify that the player is unable to cover the fee.

Medical pricing uses:

- `medicalHealCost` for heal billing.
- `medicalSpawnCost` for medical respawn billing. Respawn billing is
  best-effort so a failed charge does not block the respawn flow.

Both values can be set in the mission setup UI, mission `Params`, or
`CfgServicePricing`.

## Medical Debt Repayment

Medical fallback debt uses the existing organization credit-line repayment
flow. The organization treasury is reduced when the service is rendered, and
the player's credit-line `amount_due` increases by the medical fee. When the
player repays through the bank credit-line repayment action, player bank funds
are moved back into the organization treasury.

## Hot-Cache Boundary

The economy addon should stay server-authoritative for world effects such as
vehicle fuel, vehicle repair, healing, respawn placement, and death inventory
movement. Bank and organization balances should continue to mutate through the
extension-backed hot-cache services.
