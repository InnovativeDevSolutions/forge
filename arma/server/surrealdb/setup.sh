#!/usr/bin/env bash
set -euo pipefail

if command -v surreal >/dev/null 2>&1; then
    surreal version
    exit 0
fi

if command -v brew >/dev/null 2>&1; then
    brew install surrealdb/tap/surreal
else
    curl -sSf https://install.surrealdb.com | sh
fi

surreal version
