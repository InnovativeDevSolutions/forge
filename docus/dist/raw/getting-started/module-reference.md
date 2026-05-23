# Module Reference

This reference lists the main Forge modules and where each layer lives.

## Directory Map

```text
arma/client/addons/      Client-side Arma addons and browser UIs
arma/server/addons/      Server-side Arma addons and extension bridge
arma/server/extension/   Rust arma-rs extension and SurrealDB adapters
bin/icom/                Interprocess communication helper
lib/models/              Shared domain data models
lib/repositories/        Repository traits and in-memory stores
lib/services/            Domain services and workflow logic
lib/shared/              Cross-crate helpers
tools/                   Web UI build tooling
docs/                    Framework-level documentation
```

## Gameplay Domains

<table>
<thead>
  <tr>
    <th>
      Domain
    </th>
    
    <th>
      Purpose
    </th>
    
    <th>
      Client addon
    </th>
    
    <th>
      Server addon
    </th>
    
    <th>
      Service/model layer
    </th>
    
    <th>
      Extension group
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      Actor
    </td>
    
    <td>
      Player identity, loadout, position, status, contact identifiers, and persistent character data.
    </td>
    
    <td>
      <code>
        arma/client/addons/actor
      </code>
    </td>
    
    <td>
      <code>
        arma/server/addons/actor
      </code>
    </td>
    
    <td>
      <code>
        lib/models/src/actor.rs
      </code>
      
      , <code>
        lib/services/src/actor.rs
      </code>
    </td>
    
    <td>
      <code>
        actor:*
      </code>
    </td>
  </tr>
  
  <tr>
    <td>
      Bank
    </td>
    
    <td>
      Player accounts, cash/bank balances, PIN validation, transfers, checkout charging, and transaction context.
    </td>
    
    <td>
      <code>
        arma/client/addons/bank
      </code>
    </td>
    
    <td>
      <code>
        arma/server/addons/bank
      </code>
    </td>
    
    <td>
      <code>
        lib/models/src/bank.rs
      </code>
      
      , <code>
        lib/services/src/bank.rs
      </code>
    </td>
    
    <td>
      <code>
        bank:*
      </code>
      
      , <code>
        bank:hot:*
      </code>
    </td>
  </tr>
  
  <tr>
    <td>
      CAD
    </td>
    
    <td>
      Dispatch requests, assignments, orders, activity stream, profiles, groups, and hydrated dispatcher views.
    </td>
    
    <td>
      <code>
        arma/client/addons/cad
      </code>
    </td>
    
    <td>
      <code>
        arma/server/addons/cad
      </code>
    </td>
    
    <td>
      <code>
        lib/models/src/cad.rs
      </code>
      
      , <code>
        lib/services/src/cad.rs
      </code>
    </td>
    
    <td>
      <code>
        cad:*
      </code>
    </td>
  </tr>
  
  <tr>
    <td>
      Garage
    </td>
    
    <td>
      Player vehicle storage with plate IDs, fuel, damage, and hit point state.
    </td>
    
    <td>
      <code>
        arma/client/addons/garage
      </code>
    </td>
    
    <td>
      <code>
        arma/server/addons/garage
      </code>
    </td>
    
    <td>
      <code>
        lib/models/src/garage.rs
      </code>
      
      , <code>
        lib/services/src/garage.rs
      </code>
    </td>
    
    <td>
      <code>
        garage:*
      </code>
      
      , <code>
        garage:hot:*
      </code>
    </td>
  </tr>
  
  <tr>
    <td>
      Locker
    </td>
    
    <td>
      Player item storage keyed by classname with category and amount.
    </td>
    
    <td>
      <code>
        arma/client/addons/locker
      </code>
    </td>
    
    <td>
      <code>
        arma/server/addons/locker
      </code>
    </td>
    
    <td>
      <code>
        lib/models/src/locker.rs
      </code>
      
      , <code>
        lib/services/src/locker.rs
      </code>
    </td>
    
    <td>
      <code>
        locker:*
      </code>
      
      , <code>
        locker:hot:*
      </code>
    </td>
  </tr>
  
  <tr>
    <td>
      Organization
    </td>
    
    <td>
      Player organizations, membership, treasury, credit lines, shared assets, and fleet data.
    </td>
    
    <td>
      <code>
        arma/client/addons/org
      </code>
    </td>
    
    <td>
      <code>
        arma/server/addons/org
      </code>
    </td>
    
    <td>
      <code>
        lib/models/src/org.rs
      </code>
      
      , <code>
        lib/services/src/org.rs
      </code>
    </td>
    
    <td>
      <code>
        org:*
      </code>
      
      , <code>
        org:hot:*
      </code>
    </td>
  </tr>
  
  <tr>
    <td>
      Phone
    </td>
    
    <td>
      Contacts, messages, and email state.
    </td>
    
    <td>
      <code>
        arma/client/addons/phone
      </code>
    </td>
    
    <td>
      <code>
        arma/server/addons/phone
      </code>
    </td>
    
    <td>
      <code>
        lib/models/src/phone.rs
      </code>
      
      , <code>
        lib/services/src/phone.rs
      </code>
    </td>
    
    <td>
      <code>
        phone:*
      </code>
    </td>
  </tr>
  
  <tr>
    <td>
      Store
    </td>
    
    <td>
      Storefront entity setup, catalog hydration, checkout workflows, and checkout charging integration.
    </td>
    
    <td>
      <code>
        arma/client/addons/store
      </code>
    </td>
    
    <td>
      <code>
        arma/server/addons/store
      </code>
    </td>
    
    <td>
      <code>
        lib/models/src/store.rs
      </code>
      
      , <code>
        lib/services/src/store.rs
      </code>
    </td>
    
    <td>
      <code>
        store:checkout
      </code>
    </td>
  </tr>
  
  <tr>
    <td>
      Task
    </td>
    
    <td>
      Server-owned mission/task flows, catalog, ownership, status, participant tracking, rewards, and defuse counters.
    </td>
    
    <td>
      none
    </td>
    
    <td>
      <code>
        arma/server/addons/task
      </code>
    </td>
    
    <td>
      <code>
        lib/models/src/task.rs
      </code>
      
      , <code>
        lib/services/src/task.rs
      </code>
    </td>
    
    <td>
      <code>
        task:*
      </code>
    </td>
  </tr>
  
  <tr>
    <td>
      Owned Garage
    </td>
    
    <td>
      Organization or owner-scoped vehicle unlock storage.
    </td>
    
    <td>
      via garage/org UI
    </td>
    
    <td>
      server extension only
    </td>
    
    <td>
      <code>
        lib/models/src/v_garage.rs
      </code>
      
      , <code>
        lib/services/src/v_garage.rs
      </code>
    </td>
    
    <td>
      <code>
        owned:garage:*
      </code>
    </td>
  </tr>
  
  <tr>
    <td>
      Owned Locker
    </td>
    
    <td>
      Organization or owner-scoped arsenal unlock storage.
    </td>
    
    <td>
      via locker/org UI
    </td>
    
    <td>
      server extension only
    </td>
    
    <td>
      <code>
        lib/models/src/v_locker.rs
      </code>
      
      , <code>
        lib/services/src/v_locker.rs
      </code>
    </td>
    
    <td>
      <code>
        owned:locker:*
      </code>
    </td>
  </tr>
</tbody>
</table>

Server and extension guides:
[Actor](/server-modules/actor),
[Bank](/server-modules/bank),
[CAD](/server-modules/cad),
[Economy](/server-modules/economy),
[Garage](/server-modules/garage),
[Locker](/server-modules/locker),
[Organization](/server-modules/organization),
[Owned Storage](/server-modules/owned-storage),
[Phone](/server-modules/phone),
[Store](/server-modules/store),
[Task](/server-modules/task).

Client guides:
[Client Overview](/client-addons),
[Main](/client-addons/main),
[Common](/client-addons/common),
[Actor](/client-addons/actor),
[Bank](/client-addons/bank),
[CAD](/client-addons/cad),
[Garage](/client-addons/garage),
[Locker](/client-addons/locker),
[Notifications](/client-addons/notifications),
[Organization](/client-addons/organization),
[Phone](/client-addons/phone),
[Store](/client-addons/store).

## Infrastructure Modules

<table>
<thead>
  <tr>
    <th>
      Module
    </th>
    
    <th>
      Purpose
    </th>
    
    <th>
      Location
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        common
      </code>
    </td>
    
    <td>
      Shared SQF helpers, base stores, utility functions, and shared UI bridge pieces.
    </td>
    
    <td>
      <code>
        arma/client/addons/common
      </code>
      
      , <code>
        arma/server/addons/common
      </code>
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        extension
      </code>
    </td>
    
    <td>
      Server SQF bridge around <code>
        forge_server
      </code>
      
       extension calls and chunked transport.
    </td>
    
    <td>
      <code>
        arma/server/addons/extension
      </code>
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        main
      </code>
    </td>
    
    <td>
      Mod-level configuration, pre-init wiring, and server/client startup glue.
    </td>
    
    <td>
      <code>
        arma/client/addons/main
      </code>
      
      , <code>
        arma/server/addons/main
      </code>
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        economy
      </code>
    </td>
    
    <td>
      Server-side fuel, medical, and service economy helpers. Fuel and repair charge organization hot state; medical charges player bank/cash first, then organization funds with repayable member debt when personal funds cannot cover the bill.
    </td>
    
    <td>
      <code>
        arma/server/addons/economy
      </code>
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        notifications
      </code>
    </td>
    
    <td>
      Client notification UI, sounds, and UI event handling.
    </td>
    
    <td>
      <code>
        arma/client/addons/notifications
      </code>
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        icom
      </code>
    </td>
    
    <td>
      Rust helper for interprocess communication and event broadcasting.
    </td>
    
    <td>
      <code>
        bin/icom
      </code>
      
      , <code>
        arma/server/extension/src/icom.rs
      </code>
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        terrain
      </code>
    </td>
    
    <td>
      Extension-side terrain export helper.
    </td>
    
    <td>
      <code>
        arma/server/extension/src/terrain.rs
      </code>
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        transport
      </code>
    </td>
    
    <td>
      Chunked request/response handling for large extension payloads.
    </td>
    
    <td>
      <code>
        arma/server/extension/src/transport.rs
      </code>
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        surreal
      </code>
    </td>
    
    <td>
      SurrealDB connection lifecycle and status reporting.
    </td>
    
    <td>
      <code>
        arma/server/extension/src/surreal.rs
      </code>
    </td>
  </tr>
</tbody>
</table>

## Extension Command Groups

Commands are invoked with:

```sqf
"forge_server" callExtension ["group:command", [_arg1, _arg2]];
```

Nested groups use additional `:` separators, for example
`bank:hot:deposit`.

### Core

<table>
<thead>
  <tr>
    <th>
      Command
    </th>
    
    <th>
      Purpose
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        version
      </code>
    </td>
    
    <td>
      Return the extension version string.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        status
      </code>
    </td>
    
    <td>
      Return SurrealDB connection state.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        surreal:status
      </code>
    </td>
    
    <td>
      Return SurrealDB connection state directly from the Surreal module.
    </td>
  </tr>
</tbody>
</table>

### Actor

<table>
<thead>
  <tr>
    <th>
      Command
    </th>
    
    <th>
      Purpose
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        actor:get
      </code>
    </td>
    
    <td>
      Fetch actor data for a resolved player UID.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        actor:create
      </code>
    </td>
    
    <td>
      Create actor data from JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        actor:update
      </code>
    </td>
    
    <td>
      Apply actor JSON updates.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        actor:exists
      </code>
    </td>
    
    <td>
      Return <code>
        true
      </code>
      
       or <code>
        false
      </code>
      
      .
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        actor:delete
      </code>
    </td>
    
    <td>
      Delete actor data.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        actor:hot:init
      </code>
      
      , <code>
        actor:hot:get
      </code>
      
      , <code>
        actor:hot:keys
      </code>
      
      , <code>
        actor:hot:override
      </code>
      
      , <code>
        actor:hot:save
      </code>
      
      , <code>
        actor:hot:remove
      </code>
    </td>
    
    <td>
      Manage actor hot state.
    </td>
  </tr>
</tbody>
</table>

See [Actor Usage Guide](/server-modules/actor) for examples.

### Bank

<table>
<thead>
  <tr>
    <th>
      Command
    </th>
    
    <th>
      Purpose
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        bank:get
      </code>
      
      , <code>
        bank:create
      </code>
      
      , <code>
        bank:update
      </code>
      
      , <code>
        bank:exists
      </code>
      
      , <code>
        bank:delete
      </code>
    </td>
    
    <td>
      Durable bank CRUD.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        bank:hot:init
      </code>
      
      , <code>
        bank:hot:get
      </code>
      
      , <code>
        bank:hot:override
      </code>
      
      , <code>
        bank:hot:patch
      </code>
      
      , <code>
        bank:hot:save
      </code>
      
      , <code>
        bank:hot:remove
      </code>
    </td>
    
    <td>
      Manage bank hot state.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        bank:hot:deposit
      </code>
      
      , <code>
        bank:hot:withdraw
      </code>
      
      , <code>
        bank:hot:deposit_earnings
      </code>
      
      , <code>
        bank:hot:transfer
      </code>
    </td>
    
    <td>
      Mutate hot bank balances with operation context.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        bank:hot:charge_checkout
      </code>
    </td>
    
    <td>
      Charge a checkout against hot bank state.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        bank:hot:validate_pin
      </code>
    </td>
    
    <td>
      Validate a PIN for bank operations.
    </td>
  </tr>
</tbody>
</table>

See [Bank Usage Guide](/server-modules/bank) for examples.

### Garage

<table>
<thead>
  <tr>
    <th>
      Command
    </th>
    
    <th>
      Purpose
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        garage:create
      </code>
      
      , <code>
        garage:get
      </code>
      
      , <code>
        garage:add
      </code>
      
      , <code>
        garage:update
      </code>
      
      , <code>
        garage:patch
      </code>
      
      , <code>
        garage:remove
      </code>
      
      , <code>
        garage:delete
      </code>
      
      , <code>
        garage:exists
      </code>
    </td>
    
    <td>
      Durable player garage operations.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        garage:hot:init
      </code>
      
      , <code>
        garage:hot:get
      </code>
      
      , <code>
        garage:hot:override
      </code>
      
      , <code>
        garage:hot:add
      </code>
      
      , <code>
        garage:hot:remove_vehicle
      </code>
      
      , <code>
        garage:hot:save
      </code>
      
      , <code>
        garage:hot:remove
      </code>
    </td>
    
    <td>
      Manage player garage hot state.
    </td>
  </tr>
</tbody>
</table>

See [Garage Usage Guide](/server-modules/garage) for examples.

### Locker

<table>
<thead>
  <tr>
    <th>
      Command
    </th>
    
    <th>
      Purpose
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        locker:create
      </code>
      
      , <code>
        locker:get
      </code>
      
      , <code>
        locker:add
      </code>
      
      , <code>
        locker:update
      </code>
      
      , <code>
        locker:patch
      </code>
      
      , <code>
        locker:remove
      </code>
      
      , <code>
        locker:delete
      </code>
      
      , <code>
        locker:exists
      </code>
    </td>
    
    <td>
      Durable player locker operations.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        locker:hot:init
      </code>
      
      , <code>
        locker:hot:get
      </code>
      
      , <code>
        locker:hot:override
      </code>
      
      , <code>
        locker:hot:save
      </code>
      
      , <code>
        locker:hot:remove
      </code>
    </td>
    
    <td>
      Manage player locker hot state.
    </td>
  </tr>
</tbody>
</table>

See [Locker Usage Guide](/server-modules/locker) for examples.

### Organization

<table>
<thead>
  <tr>
    <th>
      Command
    </th>
    
    <th>
      Purpose
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        org:get
      </code>
      
      , <code>
        org:create
      </code>
      
      , <code>
        org:update
      </code>
      
      , <code>
        org:exists
      </code>
      
      , <code>
        org:delete
      </code>
    </td>
    
    <td>
      Durable organization CRUD.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:assets:get
      </code>
      
      , <code>
        org:assets:update
      </code>
    </td>
    
    <td>
      Manage organization assets.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:fleet:get
      </code>
      
      , <code>
        org:fleet:update
      </code>
    </td>
    
    <td>
      Manage organization fleet entries.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:members:get
      </code>
      
      , <code>
        org:members:add
      </code>
      
      , <code>
        org:members:remove
      </code>
    </td>
    
    <td>
      Manage organization membership.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org:hot:*
      </code>
    </td>
    
    <td>
      Runtime organization workflows including registration, invites, credit lines, checkout charging, assets, fleet, leave, disband, save, and remove.
    </td>
  </tr>
</tbody>
</table>

See [Org Usage Guide](/server-modules/organization) for examples.

### Phone

<table>
<thead>
  <tr>
    <th>
      Command
    </th>
    
    <th>
      Purpose
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        phone:init
      </code>
    </td>
    
    <td>
      Initialize phone state for a UID.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone:contacts:list
      </code>
      
      , <code>
        phone:contacts:add
      </code>
      
      , <code>
        phone:contacts:remove
      </code>
    </td>
    
    <td>
      Manage contacts.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone:messages:list
      </code>
      
      , <code>
        phone:messages:thread
      </code>
      
      , <code>
        phone:messages:send
      </code>
      
      , <code>
        phone:messages:mark_read
      </code>
      
      , <code>
        phone:messages:delete
      </code>
    </td>
    
    <td>
      Manage messages.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone:emails:list
      </code>
      
      , <code>
        phone:emails:send
      </code>
      
      , <code>
        phone:emails:mark_read
      </code>
      
      , <code>
        phone:emails:delete
      </code>
    </td>
    
    <td>
      Manage emails.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone:remove
      </code>
    </td>
    
    <td>
      Remove phone state for a UID.
    </td>
  </tr>
</tbody>
</table>

See [Phone Usage Guide](/server-modules/phone) for examples.

### CAD

<table>
<thead>
  <tr>
    <th>
      Command Group
    </th>
    
    <th>
      Purpose
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        cad:activity:append
      </code>
      
      , <code>
        cad:activity:recent
      </code>
    </td>
    
    <td>
      Append and read recent activity.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad:assignments:list
      </code>
      
      , <code>
        cad:assignments:assign
      </code>
      
      , <code>
        cad:assignments:acknowledge
      </code>
      
      , <code>
        cad:assignments:decline
      </code>
      
      , <code>
        cad:assignments:upsert
      </code>
      
      , <code>
        cad:assignments:delete
      </code>
    </td>
    
    <td>
      Manage dispatch assignments.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad:orders:list
      </code>
      
      , <code>
        cad:orders:create
      </code>
      
      , <code>
        cad:orders:create_from_context
      </code>
      
      , <code>
        cad:orders:close
      </code>
      
      , <code>
        cad:orders:upsert
      </code>
      
      , <code>
        cad:orders:delete
      </code>
    </td>
    
    <td>
      Manage orders.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad:requests:list
      </code>
      
      , <code>
        cad:requests:submit
      </code>
      
      , <code>
        cad:requests:submit_from_context
      </code>
      
      , <code>
        cad:requests:close
      </code>
      
      , <code>
        cad:requests:upsert
      </code>
      
      , <code>
        cad:requests:delete
      </code>
    </td>
    
    <td>
      Manage requests.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad:profiles:list
      </code>
      
      , <code>
        cad:profiles:update_from_context
      </code>
      
      , <code>
        cad:profiles:upsert
      </code>
      
      , <code>
        cad:profiles:delete
      </code>
    </td>
    
    <td>
      Manage profiles.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad:groups:build
      </code>
    </td>
    
    <td>
      Build grouped CAD state.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        cad:view:hydrate
      </code>
    </td>
    
    <td>
      Build the dispatcher view model.
    </td>
  </tr>
</tbody>
</table>

See [CAD Usage Guide](/server-modules/cad) for examples.

### Task

<table>
<thead>
  <tr>
    <th>
      Command Group
    </th>
    
    <th>
      Purpose
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        task:reset
      </code>
    </td>
    
    <td>
      Reset task state.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        task:catalog:active
      </code>
      
      , <code>
        task:catalog:get
      </code>
      
      , <code>
        task:catalog:upsert
      </code>
      
      , <code>
        task:catalog:delete
      </code>
    </td>
    
    <td>
      Manage task catalog entries.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        task:ownership:bind
      </code>
      
      , <code>
        task:ownership:release
      </code>
      
      , <code>
        task:ownership:accept
      </code>
      
      , <code>
        task:ownership:reward_context
      </code>
    </td>
    
    <td>
      Manage task ownership and rewards.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        task:status:set
      </code>
      
      , <code>
        task:status:get
      </code>
      
      , <code>
        task:status:clear
      </code>
    </td>
    
    <td>
      Manage task status.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        task:defuse:increment
      </code>
      
      , <code>
        task:defuse:get
      </code>
    </td>
    
    <td>
      Manage defuse counters.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        task:clear
      </code>
    </td>
    
    <td>
      Clear task state.
    </td>
  </tr>
</tbody>
</table>

See [Task Usage Guide](/server-modules/task) for examples.

### Owned Storage

<table>
<thead>
  <tr>
    <th>
      Command Group
    </th>
    
    <th>
      Purpose
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        owned:garage:create
      </code>
      
      , <code>
        owned:garage:fetch
      </code>
      
      , <code>
        owned:garage:get
      </code>
      
      , <code>
        owned:garage:add
      </code>
      
      , <code>
        owned:garage:remove
      </code>
      
      , <code>
        owned:garage:delete
      </code>
      
      , <code>
        owned:garage:exists
      </code>
    </td>
    
    <td>
      Owner-scoped vehicle storage.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        owned:garage:hot:*
      </code>
    </td>
    
    <td>
      Owner-scoped vehicle hot state.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        owned:locker:create
      </code>
      
      , <code>
        owned:locker:fetch
      </code>
      
      , <code>
        owned:locker:get
      </code>
      
      , <code>
        owned:locker:add
      </code>
      
      , <code>
        owned:locker:remove
      </code>
      
      , <code>
        owned:locker:delete
      </code>
      
      , <code>
        owned:locker:exists
      </code>
    </td>
    
    <td>
      Owner-scoped item storage.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        owned:locker:hot:*
      </code>
    </td>
    
    <td>
      Owner-scoped item hot state.
    </td>
  </tr>
</tbody>
</table>

See [Owned Storage Usage Guide](/server-modules/owned-storage) for examples.

### Other Extension Groups

<table>
<thead>
  <tr>
    <th>
      Command Group
    </th>
    
    <th>
      Purpose
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        store:checkout
      </code>
    </td>
    
    <td>
      Run store checkout behavior.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        icom:connect
      </code>
      
      , <code>
        icom:broadcast
      </code>
      
      , <code>
        icom:send_event
      </code>
    </td>
    
    <td>
      ICom connection and event forwarding.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        terrain:exportSVG
      </code>
    </td>
    
    <td>
      Export terrain data as SVG.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        transport:invoke
      </code>
      
      , <code>
        transport:invoke_stored
      </code>
    </td>
    
    <td>
      Invoke commands through transport.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        transport:request:append
      </code>
      
      , <code>
        transport:request:clear
      </code>
    </td>
    
    <td>
      Manage stored request chunks.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        transport:response:get
      </code>
      
      , <code>
        transport:response:clear
      </code>
    </td>
    
    <td>
      Manage stored response chunks.
    </td>
  </tr>
</tbody>
</table>

## Rust Crates

<table>
<thead>
  <tr>
    <th>
      Crate
    </th>
    
    <th>
      Role
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        forge-models
      </code>
    </td>
    
    <td>
      Domain models and validation. Keep these serializable and free of persistence details.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        forge-repositories
      </code>
    </td>
    
    <td>
      Repository traits and in-memory implementations. Keep these storage-agnostic.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        forge-services
      </code>
    </td>
    
    <td>
      Business rules and workflows. Depend on repository traits, not concrete databases.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        forge-shared
      </code>
    </td>
    
    <td>
      Cross-crate helpers. Keep dependencies light.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        forge-server
      </code>
    </td>
    
    <td>
      Arma extension crate. Owns command registration, SurrealDB runtime wiring, and concrete storage adapters.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        forge-icom
      </code>
    </td>
    
    <td>
      ICom helper binary and client library.
    </td>
  </tr>
</tbody>
</table>
