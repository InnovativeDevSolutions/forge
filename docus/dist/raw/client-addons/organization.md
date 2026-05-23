# Client Organization Usage Guide

The client organization addon provides the organization portal UI and browser
bridge for login, registration, membership, invites, credit lines, leave and
disband flows, assets, fleet, and treasury display.

## Open Organization UI

```sqf
call forge_client_org_fnc_openUI;
```

The UI opens `RscOrg`, loads `ui/_site/index.html`, and routes browser alerts
through `forge_client_org_fnc_handleUIEvents`.

## Repository and Bridge

`forge_client_org_fnc_initRepository` caches organization portal state.

`forge_client_org_fnc_initUIBridge` owns:

- active browser control tracking
- portal hydrate requests
- create/login response routing
- leave and disband requests
- credit-line assignment requests
- invite, accept invite, and decline invite requests
- targeted browser response events

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
        org::ready
      </code>
    </td>
    
    <td>
      Mark browser ready and request <code>
        org::sync
      </code>
      
      .
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org::login::request
      </code>
    </td>
    
    <td>
      Request portal hydrate as <code>
        org::login::success
      </code>
      
      .
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org::create::request
      </code>
    </td>
    
    <td>
      Validate org name and request creation on server.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org::disband::request
      </code>
    </td>
    
    <td>
      Request disband on server.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org::leave::request
      </code>
    </td>
    
    <td>
      Request leave on server.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org::credit::request
      </code>
    </td>
    
    <td>
      Request credit-line assignment.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org::invite::request
      </code>
    </td>
    
    <td>
      Request member invite.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org::invite::accept
      </code>
    </td>
    
    <td>
      Accept invite by org ID.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org::invite::decline
      </code>
    </td>
    
    <td>
      Decline invite by org ID.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org::close
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
        org::sync
      </code>
    </td>
    
    <td>
      Full portal sync payload.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org::login::success
      </code>
    </td>
    
    <td>
      Login hydrate payload.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org::create::success
      </code>
    </td>
    
    <td>
      Creation hydrate payload.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org::create::failure
      </code>
    </td>
    
    <td>
      Creation validation or server failure.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org::disband::success
      </code>
    </td>
    
    <td>
      Requester disband success.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org::disband::failure
      </code>
    </td>
    
    <td>
      Disband failure.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org::portal::revoked
      </code>
    </td>
    
    <td>
      Portal state revoked by someone else's disband action.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org::leave::success
      </code>
    </td>
    
    <td>
      Leave success.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org::leave::failure
      </code>
    </td>
    
    <td>
      Leave failure.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org::credit::success
      </code>
    </td>
    
    <td>
      Credit-line request success.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org::credit::failure
      </code>
    </td>
    
    <td>
      Credit-line request failure.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org::member::creditUpdated
      </code>
    </td>
    
    <td>
      Targeted member credit-line patch.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org::invite::success
      </code>
    </td>
    
    <td>
      Invite success.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org::invite::failure
      </code>
    </td>
    
    <td>
      Invite failure.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org::invite::decision::success
      </code>
    </td>
    
    <td>
      Invite accept/decline success.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        org::invite::decision::failure
      </code>
    </td>
    
    <td>
      Invite accept/decline failure.
    </td>
  </tr>
</tbody>
</table>

## Request Examples

Create organization request payload:

```json
{
  "orgName": "Example Logistics"
}
```

Credit-line request payload:

```json
{
  "memberUid": "76561198000000000",
  "memberName": "Player Name",
  "amount": 2500
}
```

Invite request payload:

```json
{
  "targetUid": "76561198000000000",
  "targetName": "Player Name"
}
```

## Authoritative State

Organization funds, reputation, membership, invites, credit lines, assets,
fleet, and persistence are server-owned. The client portal only displays and
requests changes.

## Related Guides

- [Organization Usage Guide](/server-modules/organization)
- [Client Common Usage Guide](/client-addons/common)
- [Client Bank Usage Guide](/client-addons/bank)
- [Client Store Usage Guide](/client-addons/store)
