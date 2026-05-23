# Client Phone Usage Guide

The client phone addon provides the in-game phone UI for contacts, SMS
messages, email, and local utility apps such as notes, calendar events, world
clocks, and alarms.

## Open Phone UI

```sqf
call forge_client_phone_fnc_openUI;
```

The phone UI creates `RscPhone`, loads `ui/_site/index.html`, and routes
browser alerts through `forge_client_phone_fnc_handleUIEvents`.

## State Ownership

Contacts, messages, and emails are server-owned and requested through the
server phone addon.

Local utility app state is stored in `profileNamespace`:

- notes
- calendar events
- world clocks
- alarms
- theme/preferences

## Phone Class

`forge_client_phone_fnc_initClass` creates `GVAR(PhoneClass)`.

The phone class currently owns local notes, events, and settings helpers.
Contacts, messages, and emails continue to use server-backed request/response
events.

## Browser Events

### Session and Preferences

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
        phone::get::player
      </code>
    </td>
    
    <td>
      Send player UID to browser with <code>
        setPlayerUid
      </code>
      
      .
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone::get::theme
      </code>
    </td>
    
    <td>
      Send saved light/dark theme to browser.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone::set::theme
      </code>
    </td>
    
    <td>
      Save theme preference to <code>
        profileNamespace
      </code>
      
      .
    </td>
  </tr>
</tbody>
</table>

### Contacts

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
        phone::get::contacts
      </code>
    </td>
    
    <td>
      Load cached contacts and request server refresh.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone::refresh::contacts
      </code>
    </td>
    
    <td>
      Request contacts from server.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone::add::contact
      </code>
    </td>
    
    <td>
      Add contact by phone number.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone::add::contact::by::phone
      </code>
    </td>
    
    <td>
      Add contact by phone number.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone::add::contact::by::email
      </code>
    </td>
    
    <td>
      Add contact by email.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone::remove::contact
      </code>
    </td>
    
    <td>
      Remove contact by UID.
    </td>
  </tr>
</tbody>
</table>

### Messages

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
        phone::get::messages
      </code>
    </td>
    
    <td>
      Request messages from server.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone::get::message::thread
      </code>
    </td>
    
    <td>
      Request thread with another UID.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone::send::message
      </code>
    </td>
    
    <td>
      Send SMS through server.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone::mark::message::read
      </code>
    </td>
    
    <td>
      Mark message read on server.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone::delete::message
      </code>
    </td>
    
    <td>
      Delete message on server.
    </td>
  </tr>
</tbody>
</table>

### Email

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
        phone::get::emails
      </code>
    </td>
    
    <td>
      Request emails from server.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone::send::email
      </code>
    </td>
    
    <td>
      Send email through server.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone::mark::email::read
      </code>
    </td>
    
    <td>
      Mark email read on server.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone::delete::email
      </code>
    </td>
    
    <td>
      Delete email on server.
    </td>
  </tr>
</tbody>
</table>

### Local Utility Apps

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
        phone::get::notes
      </code>
    </td>
    
    <td>
      Load local notes.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone::save::note
      </code>
    </td>
    
    <td>
      Save local note.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone::delete::note
      </code>
    </td>
    
    <td>
      Delete local note.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone::get::events
      </code>
    </td>
    
    <td>
      Load local calendar events.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone::save::event
      </code>
    </td>
    
    <td>
      Save local calendar event.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone::delete::event
      </code>
    </td>
    
    <td>
      Delete local calendar event.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone::get::clocks
      </code>
    </td>
    
    <td>
      Load local world clocks.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone::save::clock
      </code>
    </td>
    
    <td>
      Save local world clock.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone::delete::clock
      </code>
    </td>
    
    <td>
      Delete local world clock.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone::get::alarms
      </code>
    </td>
    
    <td>
      Load local alarms.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone::save::alarm
      </code>
    </td>
    
    <td>
      Save local alarm.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone::delete::alarm
      </code>
    </td>
    
    <td>
      Delete local alarm.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone::toggle::alarm
      </code>
    </td>
    
    <td>
      Toggle local alarm enabled state.
    </td>
  </tr>
</tbody>
</table>

## Usage Rules

- Send contact, message, and email mutations to the server phone addon.
- Keep local-only utility apps in `profileNamespace` until they are migrated to
server-backed storage.
- Do not treat local phone utility state as shared multiplayer state.
- Validate required UID, phone, email, subject, and message fields before
sending server requests.

## Related Guides

- [Phone Usage Guide](/server-modules/phone)
- [Client Notifications Usage Guide](/client-addons/notifications)
