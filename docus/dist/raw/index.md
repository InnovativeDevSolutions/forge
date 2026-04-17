# 

> 

<u-page-hero>
<template v-slot:title="">

Forge Framework Documentation

</template>

<template v-slot:description="">

Forge is a persistent Arma 3 framework that combines SQF addons, a Rust
`arma-rs` extension, SurrealDB persistence, shared domain crates, and
browser-backed player interfaces.

Use these docs to understand the runtime architecture, extension API surface,
server gameplay modules, and client addon integration patterns.

</template>

<template v-slot:links="">
<u-button color="primary" size="xl" to="/getting-started" trailing-icon="i-lucide-arrow-right">

Start here

</u-button>

<u-button color="neutral" size="xl" to="https://github.com/InnovativeDevSolutions/forge" icon="simple-icons-github" variant="outline">

View source

</u-button>
</template>
</u-page-hero>

<u-page-section>
<template v-slot:title="">

What Forge Covers

</template>

<template v-slot:features="">
<u-page-feature icon="i-lucide-boxes">
<template v-slot:title="">

Domain <span className="text-primary">

Modules

</span>
</template>

<template v-slot:description="">

Actor, bank, CAD, garage, locker, organization, phone, store, task, and
owned-storage workflows share a consistent service and extension model.

</template>
</u-page-feature>

<u-page-feature icon="i-lucide-server">
<template v-slot:title="">

Rust <span className="text-primary">

Extension

</span>
</template>

<template v-slot:description="">

The server extension keeps command parsing thin, routes domain requests into
services, and persists durable state through SurrealDB.

</template>
</u-page-feature>

<u-page-feature icon="i-lucide-database-zap">
<template v-slot:title="">

Durable <span className="text-primary">

Persistence

</span>
</template>

<template v-slot:description="">

Repository traits stay storage-agnostic while concrete adapters in the
extension handle schema and database mapping.

</template>
</u-page-feature>

<u-page-feature icon="i-lucide-monitor-smartphone">
<template v-slot:title="">

Browser <span className="text-primary">

UIs

</span>
</template>

<template v-slot:description="">

Client addons host web-based interfaces inside Arma displays and synchronize
state through namespaced browser bridge events.

</template>
</u-page-feature>

<u-page-feature icon="i-lucide-arrow-left-right">
<template v-slot:title="">

Transport <span className="text-primary">

Layer

</span>
</template>

<template v-slot:description="">

Large payloads move through chunked request and response transport while
smaller commands still use direct `callExtension` paths.

</template>
</u-page-feature>

<u-page-feature icon="i-lucide-wrench">
<template v-slot:title="">

Development <span className="text-primary">

Workflow

</span>
</template>

<template v-slot:description="">

The docs cover module boundaries, local validation checks, and where new
domain logic belongs across Rust, SQF, and web UI layers.

</template>
</u-page-feature>
</template>
</u-page-section>

<u-page-section>
<template v-slot:title="">

Documentation Areas

</template>

<template v-slot:features="">
<u-page-feature icon="i-lucide-rocket" to="/getting-started">
<template v-slot:title="">
<span className="text-primary">

Getting Started

</span>
</template>

<template v-slot:description="">

Framework overview, architecture, module reference, and development rules.

</template>
</u-page-feature>

<u-page-feature icon="i-lucide-server-cog" to="/server-extension">
<template v-slot:title="">

Server <span className="text-primary">

Extension

</span>
</template>

<template v-slot:description="">

Extension architecture, command surface, and SQF usage examples.

</template>
</u-page-feature>

<u-page-feature icon="i-lucide-layers-3" to="/server-modules">
<template v-slot:title="">

Server <span className="text-primary">

Modules

</span>
</template>

<template v-slot:description="">

Gameplay-domain usage guides for persistence, hot state, and command flows.

</template>
</u-page-feature>

<u-page-feature icon="i-lucide-monitor-smartphone" to="/client-addons">
<template v-slot:title="">

Client <span className="text-primary">

Addons

</span>
</template>

<template v-slot:description="">

Browser bridge, client UX entry points, and addon-specific event contracts.

</template>
</u-page-feature>
</template>
</u-page-section>
