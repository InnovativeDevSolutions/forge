# Mission Designer Guide

Build playable Forge missions in Eden with the required interaction objects,
garage markers, and CAD-compatible task modules.

This guide focuses on editor placement and mission validation. Framework
internals, extension commands, and persistence details are covered in the
developer-oriented module guides.

## Core Rule

Most Forge systems become available to players through nearby Eden objects.
Place the object, give it the correct variable name in Eden, and the server
initializer marks it with the runtime variable the actor menu scans for.

Players must be within 5 meters of the object for the actor menu to offer the
action.

## Interaction Objects

Use the object's Eden variable name, not its display name. The matching is
case-sensitive in some initializers, so use lower-case names.

![Bank object variable name field](images/eden/bank_obj_var.jpg)

| System | Eden Object Variable Name | Runtime Variable | Player Action | Notes |
| --- | --- | --- | --- | --- |
| Bank | name contains `bank` | `isBank = true` | Full bank UI | Allows full banking workflows, including PIN changes. |
| ATM | name contains `atm` | `isAtm = true` | ATM bank UI | ATM mode requires PIN authorization and does not allow PIN changes. |
| Store | name contains `store` | `isStore = true` | Store UI | Store catalog and checkout behavior are configured server-side. |
| Garage | name contains `garage` | `isGarage = true` | Garage UI and virtual garage | Include a garage category in the name or set `garageType` manually. |
| Locker | name contains `locker` | local `isLocker = true` | Virtual arsenal action | The server hides the editor object; each client creates a local locker at the same position. |

Recommended object names:

```text
atm
bank
store
locker
garage_hq
garage_hq_2
```

The example mission uses short lower-case names. Keep single-use objects simple,
add an index when there may be multiple copies, and include a site label for
garage objects so related spawn markers can share the same prefix.

Avoid using `forge_locker_box` as an editor-placed locker variable name. That
name is reserved by the client-side virtual arsenal box.

## Manual Object Variables

The automatic initializers are the normal path. If a mission script creates
interaction objects dynamically, set the same variables manually:

```sqf
_bankLaptop setVariable ["isBank", true, true];
_atmTerminal setVariable ["isAtm", true, true];
_storeCounter setVariable ["isStore", true, true];
_garageTerminal setVariable ["isGarage", true, true];
_garageTerminal setVariable ["garageType", "cars", true];
```

Supported garage types are:

- `cars`
- `armor`
- `helis`
- `planes`
- `naval`
- `other`

## Garage Markers

Garage interaction objects open the garage UI. Vehicle spawn positions come
from Eden markers.

![Garage object placement](images/eden/garage_obj.jpg)

![Garage object variable name](images/eden/garage_obj_var.jpg)

![Garage category spawn markers](images/eden/garage_spawn_mrkrs.jpg)

![Garage spawn marker variable name](images/eden/garage_spawn_1_mrkr_var.jpg)

Additional garage sites use the same pattern: place another garage interaction
object, give it a `garage` variable name that identifies the site, then place
matching category spawn markers near that garage.

![Second garage object placement](images/eden/garage_obj_2.jpg)

![Second garage object variable name](images/eden/garage_obj_2_var.jpg)

![Second garage site spawn markers](images/eden/garage_spawn_2_mrkrs.jpg)

Create empty markers near each garage site. Marker names must contain `garage`
and one supported garage category:

```text
garage_hq_cars
garage_hq_armor
garage_hq_helis
garage_hq_helis_1
garage_hq_planes
garage_hq_naval
garage_hq_other
```

This convention keeps the site and category visible in the marker name:
`garage_hq_planes` is the planes spawn marker for `garage_hq`, while
`garage_hq_2` can use another nearby set of `garage_hq_*` category markers for
the second HQ garage area. If two garage objects of the same category are close
to each other, include the full object name in the marker prefix, such as
`garage_hq_2_planes`.

Use these rules:

1. Put the marker where the vehicle should spawn.
2. Rotate the marker to control spawn heading.
3. Keep the marker close to the matching garage object.
4. Include the garage object's variable name when multiple garages exist at
   different sites.
5. Do not allow parked vehicles to block the marker. If a vehicle is within 5
   meters of the spawn position, the virtual garage blocks the session.

Vehicle spawning is strict by category. A garage without a matching category
marker cannot spawn that vehicle category.

## Store Setup

Store objects only unlock the store UI. The actual item catalog, prices,
payment source handling, locker grants, and garage unlocks are server-owned.

![Store object placement](images/eden/store_obj.jpg)

![Store object variable name](images/eden/store_obj_var.jpg)

Minimum Eden setup:

1. Place a terminal, table, NPC, or other object players can stand near.
2. Set its Eden variable name to something containing `store`.
3. Test that the actor menu shows the store action within 5 meters.

## Bank and ATM Setup

Bank and ATM objects intentionally expose different workflows.

![Bank object placement](images/eden/bank_obj.jpg)

![Bank object variable name](images/eden/bank_obj_var.jpg)

![ATM object placement](images/eden/atm_obj.jpg)

![ATM object variable name](images/eden/atm_obj_var.jpg)

Use a `bank` object for the full bank interface:

- account view
- transfers
- earnings deposit
- PIN change

Use an `atm` object for ATM access:

- PIN-gated account access
- ATM-mode banking actions
- no PIN change

Minimum Eden setup:

1. Place one or more bank laptops or terminals with variable names containing
   `bank`.
2. Place one or more ATM objects with variable names containing `atm`.
3. Keep the object accessible so players can stand within 5 meters.

## Locker Setup

Locker objects are slightly different from other interaction objects. The
server finds editor-placed objects whose variable names contain `locker`, hides
those global objects, and each client creates a local locker object at the same
position.

![Locker object placement](images/eden/locker_obj.jpg)

![Locker object variable name](images/eden/locker_obj_var.jpg)

Minimum Eden setup:

1. Place a container object where the locker should appear.
2. Set its Eden variable name to something containing `locker`.
3. Do not use `forge_locker_box`.
4. Test that the local locker appears and opens the virtual arsenal action.

## Medical Spawn Setup

The medical economy store discovers up to eleven medical spawn objects by exact
mission namespace variable name:

- `med_spawn`
- `med_spawn_1`
- `med_spawn_2`
- continuing through `med_spawn_10`

These objects are used for medical respawn placement and occupancy checks.

![Medical spawn object placement](images/eden/med_spawn_obj.jpg)

![Medical spawn object variable name](images/eden/med_spawn_obj_var.jpg)

Minimum Eden setup:

1. Place an object at each medical respawn position.
2. Set the first object's Eden variable name to `med_spawn`.
3. Set additional medical spawns to `med_spawn_1`, `med_spawn_2`, and so on.
4. Keep each spawn position clear enough for a revived player to occupy.

## CAD Access

The CAD UI is currently opened from the actor menu action path, but there is no
server initializer that marks Eden objects as dedicated CAD terminals. If a
mission needs a CAD terminal object, wire it through mission script or a custom
interaction that calls:

```sqf
[] spawn forge_client_cad_fnc_openUI;
```

Tasks show in CAD only when they are created through a CAD-compatible task
creation path.

## CEO and Dispatch Slots

Forge grants dispatch-board permissions from the player's Eden unit variable
name when that player belongs to the default organization.

Use these exact lower-case variable names:

| Slot | Eden Unit Variable Name | Permissions |
| --- | --- | --- |
| CEO | `ceo` | Can administer the default organization, use default organization funds where supported, and use the CAD dispatch board. |
| Dispatch | `dispatch` | Can use the CAD dispatch board. |

![CEO unit placement](images/eden/ceo_unit.jpg)

![CEO unit variable name](images/eden/ceo_unit_var.jpg)

![Dispatch unit placement](images/eden/dispatch_unit.jpg)

![Dispatch unit variable name](images/eden/dispatch_unit_var.jpg)

The CEO slot is intentionally broader than the dispatch slot. Use it for the
player who should administrate the default organization. Use the dispatch slot
for players who need dispatcher tools without default organization
administration rights.

## Task and CAD Setup

Mission designers should use Forge Eden task modules for CAD-visible work.
Those modules delegate to `forge_server_task_fnc_startTask`, which creates the
BIS task, registers the Forge task catalog entry, sets active task state, and
dispatches the task handler.

![Create task module placement](images/eden/create_task_mod.jpg)

![Create task module parameters](images/eden/create_task_mod_params.jpg)

![Attack task module placement](images/eden/attack_task_mod.jpg)

![Attack task module parameters](images/eden/attack_task_mod_params.jpg)

![Attack task target sync](images/eden/attack_task_tgts.jpg)

![CAD visible task](images/eden/cad-visible-task.jpg)

CAD-compatible task creation paths:

| Path | CAD Compatible | Use When |
| --- | --- | --- |
| Forge Eden task modules | Yes | Normal mission-designer workflow. |
| `forge_server_task_fnc_startTask` | Yes | Scripted or generated mission content. |
| Dynamic mission manager attack tasks | Yes | Server-generated attack missions. |
| `forge_server_task_fnc_handler` directly | Only if catalog and BIS task already exist | Advanced scripted flows. |
| Direct task function calls | No by default | Custom server-owned flows that do not need CAD assignment. |

General task rules:

1. Give every task a unique `TaskID`.
2. Set success and fail limits explicitly.
3. Use area markers for zone fields.
4. Use Forge grouping modules where required.
5. Sync task modules to real world objects, units, vehicles, or grouping
   modules.
6. Test that the task appears in CAD before relying on dispatch assignment.

Zone fields that must reference area markers:

![Task marker fields](images/eden/create_task_mod_params.jpg)

| Field | Used By | Marker Requirement |
| --- | --- | --- |
| `DefenseZone` | Defend Task | Rectangle or ellipse area marker. |
| `DeliveryZone` | Delivery Task | Rectangle or ellipse area marker. |
| `ExtZone` | Hostage and HVT capture tasks | Rectangle or ellipse area marker. |
| `CBRNZone` | Hostage CBRN variant | Rectangle or ellipse area marker. |

## Task Module Quick Reference

| Task Module | Sync Target | Required Marker |
| --- | --- | --- |
| `FORGE_Module_Attack` | Target units or vehicles | None |
| `FORGE_Module_Destroy` | Target objects, vehicles, or units | None |
| `FORGE_Module_Defuse` | `FORGE_Module_Explosives`, optionally `FORGE_Module_Protected` | None |
| `FORGE_Module_Delivery` | `FORGE_Module_Cargo` | `DeliveryZone` |
| `FORGE_Module_Hostage` | `FORGE_Module_Hostages` and `FORGE_Module_Shooters` | `ExtZone`, optional `CBRNZone` |
| `FORGE_Module_HVT` | HVT units | `ExtZone` when capture mode is enabled |
| `FORGE_Module_Defend` | Optional enemy units as wave templates | `DefenseZone` |

## Mission Manager Blacklist Markers

The dynamic mission generator avoids rectangle and ellipse area markers whose
marker name or marker text starts with `blklist`.

Use blacklist area markers to keep generated missions out of bases, spawn
areas, training zones, or protected set pieces.

![Blacklist marker placement](images/eden/blacklist_mrkr.jpg)

![Blacklist marker variable name](images/eden/blacklist_mrkr_var.jpg)

Setup:

1. Create a rectangle or ellipse area marker over the area to exclude.
2. Set the marker variable name or marker text to start with `blklist`.
3. Give the marker real size so the generator can test candidate positions
   against the area.

## Task Setup Checklist

Before publishing a mission, verify:

- Every task has a unique `TaskID`.
- Every configured marker name exists in Eden.
- Zone markers are area markers, not icon-only markers.
- Grouping modules are synced in the correct direction.
- Success and fail limits match the number of required entities.
- Reward funds and rating changes are intentional.
- The task appears in CAD when created.
- Assigned CAD tasks can be acknowledged, declined, and completed.

## Mission Validation Checklist

Run this checklist in a local multiplayer test:

- Stand within 5 meters of each bank object and verify the full bank action.
- Stand within 5 meters of each ATM and verify ATM mode.
- Confirm PIN changes are only available from the full bank interface.
- Stand near each store object and complete a test checkout.
- Stand near each locker and verify the local locker/arsenal opens.
- Open each garage and retrieve/store a vehicle.
- Open each virtual garage category and confirm the correct spawn marker is
  used.
- Block a garage spawn marker with a vehicle and confirm the warning appears.
- Create each mission task and confirm CAD visibility.
- Assign a task in CAD and verify the player flow through completion or failure.

## Eden Screenshot Set

The live docs should include real Eden screenshots for mission designers. When
capturing them, save the images under `docus/public/images/eden/` and use these
filenames so the docs can reference stable assets:

| File | Capture |
| --- | --- |
| `bank_obj.jpg`, `bank_obj_var.jpg` | Bank object placement and variable name. |
| `atm_obj.jpg`, `atm_obj_var.jpg` | ATM object placement and variable name. |
| `store_obj.jpg`, `store_obj_var.jpg` | Store object placement and variable name. |
| `locker_obj.jpg`, `locker_obj_var.jpg` | Locker container placement and variable name. |
| `garage_obj.jpg`, `garage_obj_var.jpg` | Garage interaction object placement and variable name. |
| `garage_spawn_mrkrs.jpg`, `garage_spawn_1_mrkr_var.jpg` | Garage category spawn markers and marker variable naming. |
| `garage_obj_2.jpg`, `garage_obj_2_var.jpg`, `garage_spawn_2_mrkrs.jpg` | Additional garage site placement, variable name, and spawn markers. |
| `med_spawn_obj.jpg`, `med_spawn_obj_var.jpg` | Medical spawn object placement and variable name. |
| `ceo_unit.jpg`, `ceo_unit_var.jpg` | CEO playable unit placement and variable name. |
| `dispatch_unit.jpg`, `dispatch_unit_var.jpg` | Dispatch playable unit placement and variable name. |
| `blacklist_mrkr.jpg`, `blacklist_mrkr_var.jpg` | Mission-manager blacklist marker placement and marker variable naming. |
| `create_task_mod.jpg`, `create_task_mod_params.jpg` | Generic Forge task module placement and parameters. |
| `attack_task_mod.jpg`, `attack_task_mod_params.jpg`, `attack_task_tgts.jpg` | Attack task module placement, parameters, and target sync. |
| `cad-visible-task.jpg` | In-game CAD showing a task created from the Eden module. |

Use screenshots that show the Eden left-side entity list, the selected object's
attributes panel, and the map placement where possible. Crop only enough to
remove unrelated mission content.

## Related Guides

- [Task Usage Guide](./TASK_USAGE_GUIDE.md)
- [Client Actor Usage Guide](./CLIENT_ACTOR_USAGE_GUIDE.md)
- [Client Garage Usage Guide](./CLIENT_GARAGE_USAGE_GUIDE.md)
- [Client Locker Usage Guide](./CLIENT_LOCKER_USAGE_GUIDE.md)
- [Store Usage Guide](./STORE_USAGE_GUIDE.md)
- [Bank Usage Guide](./BANK_USAGE_GUIDE.md)
- [Client CAD Usage Guide](./CLIENT_CAD_USAGE_GUIDE.md)
