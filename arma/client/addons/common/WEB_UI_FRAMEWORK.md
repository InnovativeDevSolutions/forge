# Web UI Framework Proposal

## Goal

Create a shared web UI framework inside `forge_client_common` that provides one browser runtime for all `CT_WEBBROWSER` interfaces:

- store
- bank
- garage
- org
- actor
- notifications

The framework should standardize:

- browser bootstrapping
- Arma to JS messaging
- JS to Arma messaging
- reactive state updates
- shared UI primitives
- asset loading
- teardown and remount behavior

## Why This Should Live In `common`

The current client web UIs already share the same underlying concerns:

- `A3API.RequestFile` for loading scripts and styles
- `A3API.SendAlert` for outbound events
- `ctrlWebBrowserAction ["ExecJS", ...]` for inbound events
- full-page rerender on every signal update
- duplicated runtime and bridge code across addons

That makes `forge_client_common` the right owner for:

- the browser runtime
- the bridge contract
- reusable DOM helpers
- shared components and styles

Each addon should keep only:

- app-specific state
- app-specific event names
- app-specific SQF handlers
- app-specific views and theme assets

## Constraints From `CT_WEBBROWSER`

This framework should be built for the actual browser host, not for a generic modern frontend stack.

- Browser engine should be treated as conservative Chromium/CEF.
- HTML is hosted inside the Arma browser control, not a normal web server app.
- Asset loading must work through `A3API.RequestFile`.
- Game integration must work through `A3API.SendAlert` and SQF `ExecJS`.
- Browser controls are opened and destroyed by UI displays, so mount/unmount must be explicit.
- Startup latency matters because players open these UIs interactively in-game.

## Design Principles

1. Keep the runtime small.
2. Avoid framework dependencies like React or Vue.
3. Prefer one shared bundle plus one app bundle per UI.
4. Support coarse-grained reactivity first, then targeted DOM patching where it matters.
5. Make the Arma bridge a first-class host adapter, not an afterthought.
6. Keep app logic plain JavaScript so views are easy to reason about.
7. Make every UI follow the same bootstrap contract.

## Proposed Ownership

### Common addon

`forge_client_common` should own:

- browser host adapter
- reactive runtime
- DOM renderer
- shared event bus
- base CSS tokens and utility classes
- shared components
- generic bootstrap helper
- SQF bridge base class

### Feature addons

Each feature addon should own:

- one app entrypoint
- feature store/state
- feature bridge schema
- feature views/components
- feature-specific CSS layer
- feature SQF bridge subclass/instance

## Proposed Folder Layout

```text
arma/client/addons/common/
  ui/
    src/
      runtime.js
      host.js
      bridge.js
      app.js
      index.js
    _site/
      forge-webui.js
  functions/
    fnc_initWebUIBridge.sqf
    fnc_openWebUI.sqf
    fnc_sendWebUIEvent.sqf
  README.md
  WEB_UI_FRAMEWORK.md
```

Feature addon structure would then look like:

```text
arma/client/addons/org/
  ui/
    _site/
      index.html
      app.js
      views/
      components/
      theme.css
  functions/
    fnc_initOrgUIBridge.sqf
    fnc_openUI.sqf
    fnc_handleUIEvents.sqf
```

## Runtime API Sketch

The shared runtime should expose a small API on `window.ForgeWebUI`.

### Core API

```js
ForgeWebUI = {
  h,
  text,
  fragment,
  signal,
  computed,
  effect,
  batch,
  mount,
  unmount,
  createApp,
  createBridge,
  createAssetLoader,
  createNoticeCenter,
};
```

### Reactive primitives

```js
const count = signal(0);
const doubled = computed(() => count() * 2);

effect(() => {
  console.log("count", count());
});

count.set(5);
```

Design notes:

- `signal()` returns a getter function with `.set()` and `.update()`.
- `computed()` caches until one of its dependencies changes.
- `effect()` is for bridge sync, timers, DOM subscriptions, and cleanup.
- `batch()` groups several writes into one render pass.

### DOM/rendering

```js
function CounterView() {
  return h("button", {
    onClick() {
      count.update((value) => value + 1);
    }
  }, `Count: ${count()}`);
}

mount(document.getElementById("app"), CounterView);
```

The renderer should support:

- keyed child reconciliation
- event binding
- text node updates
- conditional sections
- list rendering
- SVG nodes
- mount cleanup

It should not rebuild the whole root on every write.

## App Bootstrap Contract

Every app should use the same bootstrap shape:

```js
const app = ForgeWebUI.createApp({
  name: "org",
  root: "#app",
  setup({ host, bridge, assets, notices }) {
    const store = createOrgStore();

    bridge.on("org::sync", (payload) => {
      store.hydrate(payload);
    });

    bridge.ready();

    return () => OrgApp({ store, host, notices });
  }
});

app.start();
```

Responsibilities:

- `createApp()` locates the root node
- waits for DOM readiness
- sets up host services
- mounts the view
- wires bridge event listeners
- exposes teardown hooks

## Host Adapter API

The Arma host layer should hide `A3API` details behind one consistent service.

```js
const host = {
  isArma: true,
  requestFile(path),
  requestTexture(path, size),
  send(event, data),
  exec(name, data),
  on(event, handler),
  off(event, handler),
  ready(data),
  close(data),
};
```

Behavior:

- `send()` wraps `A3API.SendAlert(JSON.stringify(...))`
- `on()` and `off()` subscribe to messages injected from SQF
- `ready()` announces page readiness to SQF
- `close()` sends a standard close event
- if `A3API` is unavailable, fallback behavior supports local browser testing

## JS Bridge Contract

Each page should expose one stable bridge object to SQF:

```js
window.ForgeBridge.receive({
  event: "org::sync",
  data: { ... }
});
```

This replaces app-specific globals like:

- `StoreUIBridge`
- `OrgUIBridge`

Recommended interface:

```js
window.ForgeBridge = {
  receive(payload),
  receiveMany(events),
  reset(),
  ping(),
};
```

Feature apps should register handlers with the shared bridge:

```js
bridge.on("store::hydrate", handleHydrate);
bridge.on("store::checkout::success", handleCheckoutSuccess);
```

That removes duplicated payload parsing from each app bridge file.

## SQF Bridge Base Class

The SQF side should also be normalized in `common`.

### Shared base responsibilities

- find active browser control
- execute JS safely
- send `{ event, data }` payloads
- queue payloads until page ready
- flush pending payloads on ready
- standardize close handling
- standardize logging and diagnostics

### SQF API sketch

```sqf
GVAR(WebUIBridgeBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "WebUIBridgeBaseClass"],
    ["#create", compileFinal {
        _self set ["pendingEvents", []];
        _self set ["isReady", false];
    }],
    ["getActiveBrowserControl", compileFinal { ... }],
    ["execJS", compileFinal { ... }],
    ["sendEvent", compileFinal { ... }],
    ["queueEvent", compileFinal { ... }],
    ["flushPendingEvents", compileFinal { ... }],
    ["handleReady", compileFinal { ... }],
    ["handleClose", compileFinal { ... }]
];
```

Feature bridges like org or store would then extend only the behavior they need:

- payload building
- server RPC dispatch
- feature response mapping

## SQF Type Model With `createHashMapObject`

The SQF side should lean into `createHashMapObject` instead of using plain hash maps for everything.

This gives us:

- inheritance through `#base`
- explicit type tagging through `#type`
- constructors through `#create`
- cleanup through `#delete`

That is a strong fit for browser UI infrastructure because the UI layer already has clear object roles.

### Recommended types

At minimum, define these object families in `forge_client_common`:

- `IWebUIBridge`
- `IWebUIScreen`
- `IWebUIRequest`
- `IWebUISubscription`

Feature addons can then define their own types on top:

- `OrgUIBridge`
- `StoreUIBridge`
- `BankUIBridge`
- `GarageUIBridge`

### Example hierarchy

```sqf
private _webUIBridgeDeclaration = [
    ["#type", "IWebUIBridge"],
    ["#create", { ... }],
    ["getActiveBrowserControl", { ... }],
    ["sendEvent", { ... }],
    ["handleReady", { ... }],
    ["dispose", { ... }]
];

private _orgUIBridgeDeclaration = [
    ["#base", _webUIBridgeDeclaration],
    ["#type", "OrgUIBridge"],
    ["buildHydratePayload", { ... }],
    ["handleCreditResponse", { ... }]
];
```

Type checks then become straightforward:

```sqf
if ("IWebUIBridge" in (_bridge get "#type")) then {
    _bridge call ["sendEvent", ["ui::ping", createHashMap]];
};
```

### Why Example 4 matters

Example 4 on the wiki shows the important lifecycle property:

- constructor creates a resource
- object holds that resource
- destructor deletes that resource when the object is released

That pattern maps directly to UI/session resources.

### Good uses of `#delete` in this framework

- clear pending request queues
- unregister display event handlers
- null out active browser control references
- stop polling/update loops
- remove temporary mission event handlers
- release temporary response trackers

### Example use: request/response object

```sqf
private _requestDeclaration = [
    ["#type", "IWebUIRequest"],
    ["#create", {
        params ["_requestId", "_onTimeout"];
        _self set ["requestId", _requestId];
        _self set ["onTimeout", _onTimeout];
        _self set ["isResolved", false];
    }],
    ["resolve", {
        _self set ["isResolved", true];
    }],
    ["#delete", {
        if !(_self getOrDefault ["isResolved", false]) then {
            private _onTimeout = _self getOrDefault ["onTimeout", {}];
            call _onTimeout;
        };
    }]
];
```

This is the same concept as Example 4:

- object owns a resource or responsibility
- when the object is released, cleanup happens automatically

## Lifecycle Guidance

Use destructors as a cleanup safety net, not as the only control path.

Reason:

- `#delete` runs when the last reference is removed
- that is useful, but not always the best moment for gameplay/UI logic

Recommended pattern:

1. expose an explicit `dispose` or `close` method
2. perform normal cleanup there
3. let `#delete` catch anything missed

That keeps UI shutdown deterministic while still benefiting from automatic cleanup.

## Typed Screen Objects

We can also model each open browser UI as a typed screen object instead of just storing a control reference.

Example:

```sqf
private _screenDeclaration = [
    ["#type", "IWebUIScreen"],
    ["#create", {
        params ["_displayName", "_control"];
        _self set ["displayName", _displayName];
        _self set ["control", _control];
        _self set ["isReady", false];
        _self set ["pendingEvents", []];
    }],
    ["markReady", {
        _self set ["isReady", true];
    }],
    ["queueEvent", { ... }],
    ["flushPendingEvents", { ... }],
    ["dispose", {
        _self set ["pendingEvents", []];
        _self set ["control", controlNull];
    }]
];
```

That gives us a cleaner split:

- bridge object owns app-level behavior
- screen object owns one live browser control/session
- request objects own transient async work

## Recommended Application To Current Addons

The current org and store bridge objects already use `createHashMapObject`.

This should evolve into:

- one shared `IWebUIBridge` base declaration in `common`
- one shared `IWebUIScreen` declaration in `common`
- feature bridge types inheriting from `IWebUIBridge`
- optional transient request/session helper types where async cleanup matters

That will make the SQF side more explicit, easier to test, and safer around UI teardown.

## Event Naming

Keep namespaced events. The current event style is good.

Examples:

- `org::ready`
- `org::sync`
- `org::create::request`
- `store::checkout::request`
- `notifications::ready`

Standardize a small set of host-level events:

- `ui::ready`
- `ui::close`
- `ui::error`
- `ui::ping`

And keep feature events under their own namespace.

## State Model

The framework should support two store patterns:

### Local signal store

Good for:

- form state
- modal state
- selection state
- optimistic UI flags

### Domain store wrapper

Good for:

- hydrated server payloads
- catalog data
- actor action lists
- organization portal data

Recommended store API:

```js
function createStore(initialState) {
  const state = signal(initialState);

  return {
    get state() {
      return state();
    },
    patch(partial) {
      state.set({ ...state(), ...partial });
    },
    replace(next) {
      state.set(next);
    }
  };
}
```

## Component Update Model

The framework should update component subtrees, not the full UI root.

That means:

- no browser page reload
- no `innerHTML = ""` on the app root for every state change
- only components that read changed state should rerender

### Practical expectation

Examples:

- adding a member updates `MembersCard` and any member count badge
- granting a credit line updates `TreasuryCard` and the specific member row
- updating funds updates treasury summary components only
- showing a modal or notice updates only the overlay layer

## Store Contract

Each app store should expose three layers:

1. domain state signals
2. derived selectors/computed values
3. mutation methods

Recommended shape:

```js
function createOrgStore() {
  const org = signal({
    id: "",
    name: "",
    ownerUid: "",
  });

  const session = signal({
    actorUid: "",
    actorName: "",
    role: "",
    ceo: false,
  });

  const treasury = signal({
    funds: 0,
    reputation: 0,
    creditLines: [],
  });

  const roster = signal({
    members: [],
  });

  const ui = signal({
    modal: null,
    notices: [],
    treasuryTab: "overview",
  });

  const memberCount = computed(() => roster().members.length);
  const activeCreditCount = computed(() => treasury().creditLines.length);

  return {
    org,
    session,
    treasury,
    roster,
    ui,
    memberCount,
    activeCreditCount,
    hydrate(payload) { ... },
    addMember(member) { ... },
    removeMember(memberUid) { ... },
    upsertCreditLine(line) { ... },
    setFunds(amount) { ... },
    openModal(type, data) { ... },
    closeModal() { ... },
  };
}
```

### Rules

- component code reads signals directly from the store
- mutation methods are the only place that update domain state
- derived values use `computed()` instead of recalculating in every component
- UI state stays separate from domain state

## Component Contract

Components should be plain functions that subscribe only to the signals they read.

Example:

```js
function MembersCard({ store, actions }) {
  const members = store.roster().members;
  const canManageMembers = store.canManageMembers();

  return Card({
    title: "Members",
    body: List({
      items: members,
      key: (member) => member.uid,
      renderItem: (member) =>
        MemberRow({
          member,
          canRemove: canManageMembers && !store.isProtectedMember(member),
          onRemove: () => actions.removeMember(member.uid),
        }),
    }),
  });
}
```

In this model:

- `MembersCard` rerenders when `roster().members` changes
- it does not rerender when treasury funds change
- `TreasuryCard` rerenders when `treasury()` changes
- modal components rerender when `ui().modal` changes

## Patch-Oriented Mutations

Interactive actions should prefer small patch events over full app hydration.

Recommended event examples:

- `org::member::added`
- `org::member::removed`
- `org::member::creditUpdated`
- `org::treasury::fundsUpdated`
- `org::notice::show`

Initial load can still use a hydrate event:

- `org::hydrate`

But actions like assigning credit lines should not require rebuilding the full portal payload.

Example:

```js
bridge.on("org::member::creditUpdated", ({ memberUid, memberName, amount }) => {
  store.upsertCreditLine({
    uid: memberUid,
    member: memberName,
    amount,
  });
});
```

## List Reconciliation

To make targeted updates real, list rendering must be keyed.

Requirement:

- every repeated domain item must have a stable key

Examples:

- members use `uid`
- credit lines use `uid`
- assets use `className` or inventory id
- fleet entries use vehicle id

Without keyed reconciliation, a list change still forces the entire list DOM to be replaced.

## Org UI Example

Using the current organization portal as the model:

### `MembersCard`

Depends on:

- `store.roster().members`
- membership permission selectors

Should update when:

- a member is added
- a member is removed
- a member name or role changes

Should not update when:

- treasury funds change
- a modal opens
- a fleet item changes

### `TreasuryCard`

Depends on:

- `store.treasury().funds`
- `store.treasury().creditLines`
- treasury permissions
- `store.ui().treasuryTab`

Should update when:

- funds change
- a credit line is added or updated
- the user changes treasury tab

Should not update when:

- member roster changes unrelated to treasury display
- fleet changes

### `ModalLayer`

Depends on:

- `store.ui().modal`

Should update when:

- a modal opens
- a modal closes
- modal payload changes

Should not update when unrelated domain state changes.

## Mutation Examples

### Add member

```js
addMember(member) {
  this.roster.update((state) => ({
    ...state,
    members: [...state.members, member],
  }));
}
```

Only subscribers to `roster` rerender.

### Update credit line

```js
upsertCreditLine(nextLine) {
  this.treasury.update((state) => {
    const exists = state.creditLines.some((line) => line.uid === nextLine.uid);

    return {
      ...state,
      creditLines: exists
        ? state.creditLines.map((line) =>
            line.uid === nextLine.uid ? nextLine : line
          )
        : [...state.creditLines, nextLine],
    };
  });
}
```

Only subscribers to `treasury` rerender.

## Bridge Response Strategy

For responsive UIs, each server-backed action should define:

- request event
- success patch event
- failure notice event or payload

Example credit line flow:

1. JS sends `org::credit::request`
2. SQF/server validates and persists
3. SQF sends:
   - `org::member::creditUpdated` on success
   - `org::credit::failure` on failure
4. JS store applies a targeted patch
5. `TreasuryCard` and any dependent member row update

This is preferable to sending a full `org::sync` after every action.

## Shared Components

The common addon should provide plain, themeable primitives only.

Recommended first set:

- app shell
- title bar
- navbar
- modal
- notice/toast
- stat card
- empty state
- action row
- form field
- spinner
- error banner

These should accept data and callbacks, not own business logic.

## Styling Model

Use layered CSS:

1. common tokens
2. common primitives
3. feature theme
4. feature view styles

The common layer should define:

- spacing scale
- type scale
- colors
- elevation/shadows
- radius
- focus states
- motion durations

Feature UIs should override tokens rather than rewriting primitive CSS.

## Asset Loading

The loader should support:

- `A3API.RequestFile`
- `A3API.RequestTexture`
- local `fetch()` fallback for browser testing

Recommended change:

- stop loading many small scripts individually in production
- build one common runtime file and one feature app file
- keep source files split in repo, but ship bundled outputs into `_site`

That reduces browser startup cost and simplifies ordering problems.

## Error Handling

The framework should standardize:

- bridge unavailable errors
- malformed payload errors
- timeout handling for requests that expect responses
- visible in-UI notices for recoverable failures
- `console.error` plus `diag_log` friendly payloads

Recommended bridge helper:

```js
bridge.request("store::checkout::request", payload, {
  pending: "Submitting order...",
  timeoutMs: 15000,
  onTimeout() {
    notices.error("The checkout request timed out.");
  }
});
```

## Migration Plan

### Phase 1

Extract common pieces without changing app behavior:

- shared JS host adapter
- shared JS bridge
- shared signal/runtime
- shared SQF bridge base class

### Phase 2

Migrate `org` and `store` first because they already use the same custom runtime pattern.

### Phase 3

Migrate `bank`, `garage`, and `notifications`.

### Phase 4

Migrate `actor`, which may need more event-heavy interaction handling.

### Phase 5

Bundle all `_site` apps into production-ready outputs.

## First Implementation Targets

The first concrete files to build should be:

1. `arma/client/addons/common/ui/src/host.js`
2. `arma/client/addons/common/ui/src/runtime.js`
3. `arma/client/addons/common/ui/src/bridge.js`
4. `arma/client/addons/common/ui/src/app.js`
5. `arma/client/addons/common/functions/fnc_initWebUIBridge.sqf`

Those five pieces establish the core contract. After that, `org` and `store` can be migrated with low risk.

## Non-Goals

At least initially, this framework should not try to provide:

- client-side routing between pages
- SSR or pre-rendering
- JSX compilation
- TypeScript-only tooling assumptions
- a giant component system
- generalized diffing for every possible DOM edge case

This should stay focused on Arma in-browser application UIs.

## Recommended Direction

Use `forge_client_common` as the host for a small custom reactive framework, not as a dumping ground for copied app utilities.

The correct abstraction boundary is:

- `common` owns the browser platform
- each addon owns the application

That gives one UI system across the repo without forcing all screens into one monolithic app.
