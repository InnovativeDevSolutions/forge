#!/usr/bin/env bash
set -euo pipefail

if command -v brew >/dev/null 2>&1; then
    brew upgrade surrealdb/tap/surreal || brew install surrealdb/tap/surreal
else
    curl -sSf https://install.surrealdb.com | sh
fi

surreal version
