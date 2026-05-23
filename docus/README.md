# Forge Docs

This directory contains the online documentation site for the Forge framework.
The site is built with Nuxt and Docus, and its content is generated from the
repository's source markdown files.

## Local Development

Install dependencies:

```powershell
npm install
```

Start the docs site:

```powershell
npm run dev
```

The content tree is refreshed automatically from:

- `docs/`
- `arma/server/docs/`

## Production Build

```powershell
npm run build
```

Use these environment variables when deploying to a custom host:

- `DOCS_BASE_URL`
- `DOCS_SITE_URL`
- `DOCS_REPO_URL`
- `DOCS_REPO_BRANCH`
