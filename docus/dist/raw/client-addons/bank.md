# Client Bank Usage Guide

The client bank addon opens the bank and ATM browser UI, forwards banking
requests to the server bank addon, and pushes account updates back into the
browser.

## Open Bank UI

Open full bank mode:

```sqf
call forge_client_bank_fnc_openUI;
```

Open ATM mode:

```sqf
[true] call forge_client_bank_fnc_openUI;
```

The open function creates `RscBank`, sets the bridge mode to `bank` or `atm`,
loads `ui/_site/index.html`, and routes browser events through
`forge_client_bank_fnc_handleUIEvents`.

## Bridge and Repository

`forge_client_bank_fnc_initRepository` tracks account load and cached account
state.

`forge_client_bank_fnc_initUIBridge` owns:

- active browser control tracking
- bank/ATM mode
- browser ready handling
- account hydrate and sync responses
- deposit, withdrawal, transfer, earnings deposit, credit repayment, and PIN
requests
- browser notice delivery

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
        bank::ready
      </code>
    </td>
    
    <td>
      Mark browser ready and request hydrate from the server.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        bank::refresh
      </code>
    </td>
    
    <td>
      Request fresh bank hydrate data.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        bank::deposit::request
      </code>
    </td>
    
    <td>
      Forward deposit amount to the server.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        bank::withdraw::request
      </code>
    </td>
    
    <td>
      Forward withdrawal amount to the server.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        bank::transfer::request
      </code>
    </td>
    
    <td>
      Forward target, source field, and amount.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        bank::depositEarnings::request
      </code>
    </td>
    
    <td>
      Request earnings deposit.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        bank::repayCreditLine::request
      </code>
    </td>
    
    <td>
      Request credit-line repayment.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        bank::pin::request
      </code>
    </td>
    
    <td>
      Forward PIN validation request.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        bank::close
      </code>
    </td>
    
    <td>
      Dispose bridge screen state and close the display.
    </td>
  </tr>
</tbody>
</table>

## Browser Response Events

The bridge sends:

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
        bank::hydrate
      </code>
    </td>
    
    <td>
      Full session/account payload.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        bank::sync
      </code>
    </td>
    
    <td>
      Account patch or sync data.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        bank::notice
      </code>
    </td>
    
    <td>
      UI-visible notice payload.
    </td>
  </tr>
</tbody>
</table>

## Request Flow

Example deposit flow:

1. Browser sends `bank::deposit::request` with an `amount`.
2. Client bridge calls the server bank request event.
3. Server bank addon validates the request and calls bank hot-state logic.
4. Server response is caught by the client post-init event handlers.
5. Client bridge sends `bank::sync` or `bank::notice` back to the browser.

## Authoritative State

Balances, PIN authorization, transfers, checkout charges, credit lines, and
persistence are server-owned. The client should only display account data and
request mutations through server events.

## Related Guides

- [Bank Usage Guide](/server-modules/bank)
- [Client Common Usage Guide](/client-addons/common)
- [Client Store Usage Guide](/client-addons/store)
