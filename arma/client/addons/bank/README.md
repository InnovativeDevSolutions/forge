# Forge Client Bank

## Overview
The bank addon provides the client banking UI and browser bridge for account
hydrate, deposits, withdrawals, transfers, PIN entry, earnings deposits, and
credit-line repayment.

## Dependencies
- `forge_client_common`
- `forge_client_main`
- server bank events from `forge_server_bank`
- notifications for server-driven messages

## Main Components
- `fnc_initRepository.sqf` tracks account load state.
- `fnc_initUIBridge.sqf` translates browser requests into server RPCs and sends
  server responses back to the browser.
- `fnc_handleUIEvents.sqf` handles `bank::*` browser events.
- `fnc_openUI.sqf` opens `RscBank`; ATM mode is supported by passing `true`.

## Browser Events
- `bank::ready`
- `bank::refresh`
- `bank::deposit::request`
- `bank::withdraw::request`
- `bank::transfer::request`
- `bank::depositEarnings::request`
- `bank::repayCreditLine::request`
- `bank::pin::request`
- `bank::close`

## Runtime Notes
The client only displays and requests account changes. The server bank addon and
extension own validation, balances, authorization, and persistence.
