# Client Store Usage Guide

The client store addon provides the storefront browser UI for catalog browsing,
category hydration, payment source display, cart handling, and checkout
requests.

## Open Store UI

```sqf
call forge_client_store_fnc_openUI;
```

The UI opens `RscStore`, loads `ui/_site/index.html`, and routes browser alerts
through `forge_client_store_fnc_handleUIEvents`.

## Bridge

`forge_client_store_fnc_initUIBridge` owns:

- browser control lookup
- store hydrate requests
- category requests
- checkout requests
- category hydrate/failure responses
- checkout success/failure responses
- store config refresh after successful checkout

Store currently uses its own `StoreUIBridge.receive(...)` browser bridge rather
than the shared `ForgeBridge.receive(...)` delivery used by newer bridges.

## Browser Events

<table>
<thead>
  <tr>
    <th>
      Event
    </th>
    
    <th>
      Client behavior
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        store::ready
      </code>
    </td>
    
    <td>
      Request store hydrate from the server.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        store::category::request
      </code>
    </td>
    
    <td>
      Request catalog items for a category.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        store::checkout::request
      </code>
    </td>
    
    <td>
      Forward checkout JSON to the server.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        store::close
      </code>
    </td>
    
    <td>
      Close the display.
    </td>
  </tr>
</tbody>
</table>

## Browser Response Events

<table>
<thead>
  <tr>
    <th>
      Event
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
        store::hydrate
      </code>
    </td>
    
    <td>
      Initial storefront/session/config payload.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        store::config::hydrate
      </code>
    </td>
    
    <td>
      Refreshed payment/source config.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        store::category::hydrate
      </code>
    </td>
    
    <td>
      Category catalog payload.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        store::category::failure
      </code>
    </td>
    
    <td>
      Category request failure.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        store::checkout::success
      </code>
    </td>
    
    <td>
      Checkout success payload.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        store::checkout::failure
      </code>
    </td>
    
    <td>
      Checkout failure payload.
    </td>
  </tr>
</tbody>
</table>

## Category Requests

Category requests require a non-empty category value.

```json
{
  "category": "weapons"
}
```

The client lowercases the category before forwarding it to the server store
addon.

## Checkout Requests

Checkout requests send a serialized checkout payload:

```json
{
  "checkoutJson": "{\"items\":[],\"paymentSource\":\"cash\"}"
}
```

The client only forwards the checkout data. The server store addon and
extension validate prices, inventory grants, payment source authorization, and
integration with bank, organization, locker, and garage state.

After a successful checkout, the client asks the server for a fresh store config
payload so payment-source balances and permissions stay current.

## Authoritative State

Catalog data, prices, checkout validation, money movement, organization funds,
credit lines, locker grants, garage grants, and persistence are server-owned.

## Related Guides

- [Store Usage Guide](/server-modules/store)
- [Client Bank Usage Guide](/client-addons/bank)
- [Client Organization Usage Guide](/client-addons/organization)
- [Client Locker Usage Guide](/client-addons/locker)
- [Client Garage Usage Guide](/client-addons/garage)
