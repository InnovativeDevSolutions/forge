import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const docusDir = path.join(repoRoot, 'docus');
const contentDir = path.join(docusDir, 'content');

const generatedPages = [
  {
    source: 'docs/FRAMEWORK_ARCHITECTURE.md',
    target: '1.getting-started/1.architecture.md'
  },
  {
    source: 'docs/MODULE_REFERENCE.md',
    target: '1.getting-started/2.module-reference.md'
  },
  {
    source: 'docs/DEVELOPMENT_GUIDE.md',
    target: '1.getting-started/3.development.md'
  },
  {
    source: 'docs/GIT_WORKFLOW.md',
    target: '1.getting-started/4.git-workflow.md'
  },
  {
    source: 'docs/MISSION_DESIGNER_GUIDE.md',
    target: '1.getting-started/5.mission-designer.md'
  },
  {
    source: 'docs/PLAYER_GUIDE.md',
    target: '1.getting-started/6.player-guide.md'
  },
  {
    source: 'docs/surrealdb-setup.md',
    target: '1.getting-started/7.surrealdb-setup.md'
  },
  {
    source: 'arma/server/docs/README.md',
    target: '2.server-extension/0.index.md'
  },
  {
    source: 'arma/server/docs/api-reference.md',
    target: '2.server-extension/1.api-reference.md'
  },
  {
    source: 'arma/server/docs/usage-examples.md',
    target: '2.server-extension/2.usage-examples.md'
  },
  {
    source: 'arma/server/addons/common/README.md',
    target: '2.server-extension/3.common.md'
  },
  {
    source: 'docs/ICOM_USAGE_GUIDE.md',
    target: '2.server-extension/4.icom.md'
  },
  {
    source: 'docs/ACTOR_USAGE_GUIDE.md',
    target: '3.server-modules/1.actor.md'
  },
  {
    source: 'docs/BANK_USAGE_GUIDE.md',
    target: '3.server-modules/2.bank.md'
  },
  {
    source: 'docs/CAD_USAGE_GUIDE.md',
    target: '3.server-modules/3.cad.md'
  },
  {
    source: 'docs/ECONOMY_USAGE_GUIDE.md',
    target: '3.server-modules/4.economy.md'
  },
  {
    source: 'docs/GARAGE_USAGE_GUIDE.md',
    target: '3.server-modules/5.garage.md'
  },
  {
    source: 'docs/LOCKER_USAGE_GUIDE.md',
    target: '3.server-modules/6.locker.md'
  },
  {
    source: 'docs/ORG_USAGE_GUIDE.md',
    target: '3.server-modules/7.organization.md'
  },
  {
    source: 'docs/OWNED_STORAGE_USAGE_GUIDE.md',
    target: '3.server-modules/8.owned-storage.md'
  },
  {
    source: 'docs/PHONE_USAGE_GUIDE.md',
    target: '3.server-modules/9.phone.md'
  },
  {
    source: 'docs/STORE_USAGE_GUIDE.md',
    target: '3.server-modules/10.store.md'
  },
  {
    source: 'docs/TASK_USAGE_GUIDE.md',
    target: '3.server-modules/11.task.md'
  },
  {
    source: 'docs/CLIENT_USAGE_GUIDE.md',
    target: '4.client-addons/0.index.md'
  },
  {
    source: 'docs/CLIENT_MAIN_USAGE_GUIDE.md',
    target: '4.client-addons/1.main.md'
  },
  {
    source: 'docs/CLIENT_COMMON_USAGE_GUIDE.md',
    target: '4.client-addons/2.common.md'
  },
  {
    source: 'docs/CLIENT_ACTOR_USAGE_GUIDE.md',
    target: '4.client-addons/3.actor.md'
  },
  {
    source: 'docs/CLIENT_BANK_USAGE_GUIDE.md',
    target: '4.client-addons/4.bank.md'
  },
  {
    source: 'docs/CLIENT_CAD_USAGE_GUIDE.md',
    target: '4.client-addons/5.cad.md'
  },
  {
    source: 'docs/CLIENT_GARAGE_USAGE_GUIDE.md',
    target: '4.client-addons/6.garage.md'
  },
  {
    source: 'docs/CLIENT_LOCKER_USAGE_GUIDE.md',
    target: '4.client-addons/7.locker.md'
  },
  {
    source: 'docs/CLIENT_NOTIFICATIONS_USAGE_GUIDE.md',
    target: '4.client-addons/8.notifications.md'
  },
  {
    source: 'docs/CLIENT_ORG_USAGE_GUIDE.md',
    target: '4.client-addons/9.organization.md'
  },
  {
    source: 'docs/CLIENT_PHONE_USAGE_GUIDE.md',
    target: '4.client-addons/10.phone.md'
  },
  {
    source: 'docs/CLIENT_STORE_USAGE_GUIDE.md',
    target: '4.client-addons/11.store.md'
  }
];

const virtualRoutes = new Map([
  ['README.md', '/getting-started'],
  ['docs/README.md', '/getting-started']
]);

for (const page of generatedPages) {
  virtualRoutes.set(toPosix(page.source), toRoute(page.target));
}

const staticFiles = [
  {
    target: 'index.md',
    content: `---
seo:
  title: Forge Framework Documentation
  description: Documentation for the Forge Arma 3 framework, covering architecture, persistence, extension APIs, gameplay modules, and client UIs.
---

::u-page-hero
#title
Forge Framework Documentation

#description
Forge is a persistent Arma 3 framework that combines SQF addons, a Rust
\`arma-rs\` extension, SurrealDB persistence, shared domain crates, and
browser-backed player interfaces.

Use these docs to understand the runtime architecture, extension API surface,
server gameplay modules, and client addon integration patterns.

Server owners and developers must start SurrealDB and place a matching
\`config.toml\` beside \`forge_server_x64.dll\` before launching a
Forge-enabled server or local multiplayer test.

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
  smaller commands still use direct \`callExtension\` paths.
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
`
  },
  {
    target: '1.getting-started/.navigation.yml',
    content: `title: Getting Started
icon: i-lucide-rocket
`
  },
  {
    target: '1.getting-started/0.index.md',
    content: `---
title: Getting Started
description: Use this section as the main entry point for the Forge framework.
---

Forge combines:

- Arma 3 client addons for UX and browser-hosted interfaces
- Arma 3 server addons for mission integration and authoritative flow control
- a Rust server extension for command routing and persistence
- shared Rust crates for models, repositories, and services
- SurrealDB for durable storage

## Launch Prerequisites

Before starting a Forge-enabled dedicated server or local multiplayer test,
server owners and developers must start SurrealDB and make sure
\`config.toml\` is beside \`forge_server_x64.dll\`. The config values must match
the running SurrealDB endpoint, namespace, database, username, and password.

Mission designers and players do not need their own SurrealDB instance unless
they are hosting locally, but the server they join must have these prerequisites
ready.

## Common Commands

\`\`\`powershell
cargo test
npm run build:webui
.\\build-arma.ps1
\`\`\`

## Start Here

::u-page-grid
  :::u-page-card
  ---
  icon: i-lucide-network
  title: Architecture
  to: /getting-started/architecture
  ---
  Understand how SQF, Rust services, SurrealDB, and browser UIs fit together.
  :::

  :::u-page-card
  ---
  icon: i-lucide-boxes
  title: Module Reference
  to: /getting-started/module-reference
  ---
  Review gameplay domains, infrastructure modules, and extension command groups.
  :::

  :::u-page-card
  ---
  icon: i-lucide-wrench
  title: Development Guide
  to: /getting-started/development
  ---
  See the rules for adding modules and changing boundaries without regressions.
  :::

  :::u-page-card
  ---
  icon: i-lucide-git-branch
  title: Git Workflow
  to: /getting-started/git-workflow
  ---
  Follow the branch roles, release baseline, mission storage, and helper commands
  used by the Forge repository.
  :::

  :::u-page-card
  ---
  icon: i-lucide-map
  title: Mission Designer Guide
  to: /getting-started/mission-designer
  ---
  Place Eden interaction objects, garage markers, and Forge task modules for
  playable missions.
  :::

  :::u-page-card
  ---
  icon: i-lucide-user-round-check
  title: Player Guide
  to: /getting-started/player-guide
  ---
  Learn the player-facing CAD, phone, bank, store, locker, garage, and economy
  workflows.
  :::

  :::u-page-card
  ---
  icon: i-lucide-database
  title: SurrealDB Setup
  to: /getting-started/surrealdb-setup
  ---
  Install SurrealDB, match Forge config values, and choose the right setup path
  for developers or admin-facing roles.
  :::

  :::u-page-card
  ---
  icon: i-lucide-server-cog
  title: Server Extension
  to: /server-extension
  ---
  Follow the extension architecture, API surface, and SQF usage examples.
  :::

  :::u-page-card
  ---
  icon: i-lucide-layers-3
  title: Server Modules
  to: /server-modules
  ---
  Dive into the actor, bank, CAD, garage, locker, organization, phone, store,
  task, and owned-storage guides.
  :::

  :::u-page-card
  ---
  icon: i-lucide-monitor-smartphone
  title: Client Addons
  to: /client-addons
  ---
  Explore the client bridge model and addon-specific browser integration rules.
  :::
::
`
  },
  {
    target: '2.server-extension/.navigation.yml',
    content: `title: Forge Server Extension
icon: i-lucide-server-cog
`
  },
  {
    target: '3.server-modules/.navigation.yml',
    content: `title: Server Modules
icon: i-lucide-layers-3
`
  },
  {
    target: '3.server-modules/0.index.md',
    content: `---
title: Server Module Guides
description: These pages document the authoritative server-side workflows in Forge.
---

Most modules follow the same shape:

1. Server SQF gathers game context and validates mission/runtime assumptions.
2. The \`forge_server\` extension routes the request into the matching command group.
3. Services apply business rules through storage-agnostic repository traits.
4. The extension persists durable state through SurrealDB adapters when needed.

## Gameplay Domains

::u-page-grid
  :::u-page-card
  ---
  icon: i-lucide-user-round
  title: Actor
  to: /server-modules/actor
  ---
  Persistent player identity, position, loadout, contact fields, and hot state.
  :::

  :::u-page-card
  ---
  icon: i-lucide-wallet
  title: Bank
  to: /server-modules/bank
  ---
  Player funds, transfers, PIN validation, checkout charging, and bank hot state.
  :::

  :::u-page-card
  ---
  icon: i-lucide-map
  title: CAD
  to: /server-modules/cad
  ---
  Dispatch requests, assignments, profiles, grouped state, and hydrated views.
  :::

  :::u-page-card
  ---
  icon: i-lucide-ambulance
  title: Economy
  to: /server-modules/economy
  ---
  Fuel, service, and medical charging rules across player and organization funds.
  :::

  :::u-page-card
  ---
  icon: i-lucide-car-front
  title: Garage
  to: /server-modules/garage
  ---
  Vehicle storage, hot-state updates, and persistence of vehicle condition.
  :::

  :::u-page-card
  ---
  icon: i-lucide-package
  title: Locker
  to: /server-modules/locker
  ---
  Player inventory storage, unique item limits, and locker hot-state behavior.
  :::

  :::u-page-card
  ---
  icon: i-lucide-building-2
  title: Organization
  to: /server-modules/organization
  ---
  Membership, treasury, shared assets, fleet, and organization hot workflows.
  :::

  :::u-page-card
  ---
  icon: i-lucide-key-round
  title: Owned Storage
  to: /server-modules/owned-storage
  ---
  Owner-scoped locker and vehicle unlock storage used by org-linked features.
  :::

  :::u-page-card
  ---
  icon: i-lucide-smartphone
  title: Phone
  to: /server-modules/phone
  ---
  Contacts, message threads, and email state for in-game phone workflows.
  :::

  :::u-page-card
  ---
  icon: i-lucide-shopping-cart
  title: Store
  to: /server-modules/store
  ---
  Checkout orchestration across pricing, grants, payment sources, and rollback.
  :::

  :::u-page-card
  ---
  icon: i-lucide-flag
  title: Task
  to: /server-modules/task
  ---
  Task catalog, ownership, status transitions, defuse counters, and rewards.
  :::
::
`
  },
  {
    target: '4.client-addons/.navigation.yml',
    content: `title: Client Addons
icon: i-lucide-monitor-smartphone
`
  }
];

await fs.rm(contentDir, { recursive: true, force: true });
await fs.mkdir(contentDir, { recursive: true });

for (const file of staticFiles) {
  await writeContentFile(file.target, file.content);
}

for (const page of generatedPages) {
  const sourceRel = toPosix(page.source);
  const sourcePath = path.join(repoRoot, page.source);
  const rawContent = await fs.readFile(sourcePath, 'utf8');
  const content = prepareGeneratedPageContent(rewriteMarkdownLinks(rawContent, sourceRel));
  await writeContentFile(page.target, content);
}

console.log(`Generated ${staticFiles.length + generatedPages.length} Docus content files.`);

function rewriteMarkdownLinks(content, sourceRel) {
  const sourceDir = path.posix.dirname(sourceRel);

  return content.replace(/\]\(([^)]+)\)/g, (match, rawTarget) => {
    if (
      rawTarget.startsWith('http://') ||
      rawTarget.startsWith('https://') ||
      rawTarget.startsWith('#') ||
      rawTarget.startsWith('mailto:')
    ) {
      return match;
    }

    const [targetPath, targetHash] = rawTarget.split('#');
    if (!targetPath || !targetPath.toLowerCase().endsWith('.md')) {
      return match;
    }

    const normalizedTarget = toPosix(
      path.posix.normalize(path.posix.join(sourceDir, targetPath.replace(/\\/g, '/')))
    );
    const route = virtualRoutes.get(normalizedTarget);
    if (!route) {
      return match;
    }

    return `](${route}${targetHash ? `#${targetHash}` : ''})`;
  });
}

function prepareGeneratedPageContent(content) {
  const title = extractFirstH1(content);
  const description = extractLeadParagraph(content);
  const body = stripMatchingLeadParagraph(stripFirstH1(content), description).trimStart();
  const frontmatter = [
    '---',
    title ? `title: ${yamlString(title)}` : undefined,
    description ? `description: ${yamlString(description)}` : undefined,
    '---'
  ].filter(Boolean).join('\n');

  return `${frontmatter}\n\n${body}`;
}

function extractFirstH1(content) {
  const match = content.match(/^#\s+(.+?)\s*#*\s*$/m);
  return match ? match[1].trim() : '';
}

function extractLeadParagraph(content) {
  const lines = stripFirstH1(content).split(/\r?\n/);

  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index].trim();
    if (!line) {
      continue;
    }

    if (!isParagraphStart(line)) {
      continue;
    }

    const paragraph = [];
    for (let paragraphIndex = index; paragraphIndex < lines.length; paragraphIndex += 1) {
      const paragraphLine = lines[paragraphIndex].trim();
      if (!paragraphLine) {
        break;
      }

      paragraph.push(paragraphLine);
    }

    return normalizeParagraph(paragraph.join(' '));
  }

  return '';
}

function stripFirstH1(content) {
  const lines = content.split(/\r?\n/);
  const headingIndex = lines.findIndex((line) => /^#\s+.+/.test(line.trim()));
  if (headingIndex === -1) {
    return content;
  }

  lines.splice(headingIndex, 1);
  while (headingIndex < lines.length && !lines[headingIndex].trim()) {
    lines.splice(headingIndex, 1);
  }

  return lines.join('\n');
}

function stripMatchingLeadParagraph(content, description) {
  if (!description) {
    return content;
  }

  const lines = content.split(/\r?\n/);
  let startIndex = 0;
  while (startIndex < lines.length && !lines[startIndex].trim()) {
    startIndex += 1;
  }

  if (startIndex < lines.length && /^##\s+overview\s*$/i.test(lines[startIndex].trim())) {
    const sectionStart = startIndex;
    startIndex += 1;
    while (startIndex < lines.length && !lines[startIndex].trim()) {
      startIndex += 1;
    }

    let sectionEnd = startIndex;
    const sectionLines = [];
    while (sectionEnd < lines.length && !/^#{2,}\s+/.test(lines[sectionEnd].trim())) {
      if (lines[sectionEnd].trim()) {
        sectionLines.push(lines[sectionEnd].trim());
      }

      sectionEnd += 1;
    }

    if (normalizeParagraph(sectionLines.join(' ')) === description) {
      while (sectionEnd < lines.length && !lines[sectionEnd].trim()) {
        sectionEnd += 1;
      }

      return [...lines.slice(0, sectionStart), ...lines.slice(sectionEnd)].join('\n');
    }

    startIndex = sectionStart;
  }

  if (startIndex >= lines.length || !isParagraphStart(lines[startIndex].trim())) {
    return content;
  }

  let endIndex = startIndex;
  const paragraph = [];
  while (endIndex < lines.length && lines[endIndex].trim()) {
    paragraph.push(lines[endIndex].trim());
    endIndex += 1;
  }

  if (normalizeParagraph(paragraph.join(' ')) !== description) {
    return content;
  }

  while (endIndex < lines.length && !lines[endIndex].trim()) {
    endIndex += 1;
  }

  return [...lines.slice(0, startIndex), ...lines.slice(endIndex)].join('\n');
}

function isParagraphStart(line) {
  return !(
    line.startsWith('#') ||
    line.startsWith('![') ||
    line.startsWith('```') ||
    line.startsWith(':::') ||
    line.startsWith('::') ||
    line.startsWith('|') ||
    /^[-*+]\s+/.test(line) ||
    /^\d+\.\s+/.test(line)
  );
}

function normalizeParagraph(value) {
  return value.replace(/\s+/g, ' ').trim();
}

function yamlString(value) {
  return JSON.stringify(value);
}

function toRoute(target) {
  const withoutExt = toPosix(target).replace(/\.md$/i, '');
  const parts = withoutExt.split('/');

  if (parts.length === 1 && parts[0] === 'index') {
    return '/';
  }

  const mapped = parts
    .map((part, index) => {
      if (index === parts.length - 1 && (part === '0.index' || part === 'index')) {
        return '';
      }

      return part.replace(/^\d+\./, '');
    })
    .filter(Boolean);

  return `/${mapped.join('/')}`;
}

function toPosix(value) {
  return value.replace(/\\/g, '/');
}

async function writeContentFile(target, content) {
  const targetPath = path.join(contentDir, target);
  await fs.mkdir(path.dirname(targetPath), { recursive: true });
  await fs.writeFile(targetPath, content.endsWith('\n') ? content : `${content}\n`, 'utf8');
}
