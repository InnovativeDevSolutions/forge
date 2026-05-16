---
seo:
  title: Forge Framework Documentation
  description: Documentation for the Forge Arma 3 framework, covering architecture, persistence, extension APIs, gameplay modules, and client UIs.
---

::u-page-hero
#title
Forge Framework Documentation

#description
Forge is a persistent Arma 3 framework that combines SQF addons, a Rust
`arma-rs` extension, SurrealDB persistence, shared domain crates, and
browser-backed player interfaces.

Use these docs to understand the runtime architecture, extension API surface,
server gameplay modules, and client addon integration patterns.

#links
  :::u-button
  ---
  color: primary
  size: xl
  to: /getting-started
  trailing-icon: i-lucide-arrow-right
  ---
  Start here
  :::

  :::u-button
  ---
  color: neutral
  icon: simple-icons-github
  size: xl
  to: https://github.com/InnovativeDevSolutions/forge
  variant: outline
  ---
  View source
  :::
::

::u-page-section
#title
What Forge Covers

#features
  :::u-page-feature
  ---
  icon: i-lucide-boxes
  ---
  #title
  Domain [Modules]{.text-primary}

  #description
  Actor, bank, CAD, garage, locker, organization, phone, store, task, and
  owned-storage workflows share a consistent service and extension model.
  :::

  :::u-page-feature
  ---
  icon: i-lucide-server
  ---
  #title
  Rust [Extension]{.text-primary}

  #description
  The server extension keeps command parsing thin, routes domain requests into
  services, and persists durable state through SurrealDB.
  :::

  :::u-page-feature
  ---
  icon: i-lucide-database-zap
  ---
  #title
  Durable [Persistence]{.text-primary}

  #description
  Repository traits stay storage-agnostic while concrete adapters in the
  extension handle schema and database mapping.
  :::

  :::u-page-feature
  ---
  icon: i-lucide-monitor-smartphone
  ---
  #title
  Browser [UIs]{.text-primary}

  #description
  Client addons host web-based interfaces inside Arma displays and synchronize
  state through namespaced browser bridge events.
  :::

  :::u-page-feature
  ---
  icon: i-lucide-arrow-left-right
  ---
  #title
  Transport [Layer]{.text-primary}

  #description
  Large payloads move through chunked request and response transport while
  smaller commands still use direct `callExtension` paths.
  :::

  :::u-page-feature
  ---
  icon: i-lucide-wrench
  ---
  #title
  Development [Workflow]{.text-primary}

  #description
  The docs cover module boundaries, local validation checks, and where new
  domain logic belongs across Rust, SQF, and web UI layers.
  :::
::

::u-page-section
#title
Documentation Areas

#features
  :::u-page-feature
  ---
  icon: i-lucide-rocket
  to: /getting-started
  ---
  #title
  [Getting Started]{.text-primary}

  #description
  Framework overview, architecture, module reference, and development rules.
  :::

  :::u-page-feature
  ---
  icon: i-lucide-map
  to: /getting-started/mission-designer
  ---
  #title
  Mission [Designers]{.text-primary}

  #description
  Eden object placement, garage markers, and CAD-compatible task setup.
  :::

  :::u-page-feature
  ---
  icon: i-lucide-server-cog
  to: /server-extension
  ---
  #title
  Server [Extension]{.text-primary}

  #description
  Extension architecture, command surface, and SQF usage examples.
  :::

  :::u-page-feature
  ---
  icon: i-lucide-network
  to: /server-extension/icom
  ---
  #title
  ICOM [Events]{.text-primary}

  #description
  Inter-server event routing through the Forge ICOM hub and extension commands.
  :::

  :::u-page-feature
  ---
  icon: i-lucide-layers-3
  to: /server-modules
  ---
  #title
  Server [Modules]{.text-primary}

  #description
  Gameplay-domain usage guides for persistence, hot state, and command flows.
  :::

  :::u-page-feature
  ---
  icon: i-lucide-monitor-smartphone
  to: /client-addons
  ---
  #title
  Client [Addons]{.text-primary}

  #description
  Browser bridge, client UX entry points, and addon-specific event contracts.
  :::
::
