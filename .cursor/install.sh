#!/usr/bin/env bash
# Idempotent dependency setup for claude-mem Cloud Agents.
# Runs from any working directory. Bun is linked into /usr/local/bin so
# non-interactive login shells (install and start) can find it.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if ! command -v bun >/dev/null 2>&1; then
  curl -fsSL https://bun.sh/install | bash
fi

if [[ -x "${HOME}/.bun/bin/bun" ]]; then
  sudo ln -sfn "${HOME}/.bun/bin/bun" /usr/local/bin/bun
fi

hash -r
command -v bun >/dev/null
bun --version

# Semantic search spawns `uvx --python 3.13 chroma-mcp`. Put uv/uvx on the
# default PATH and install that Python so the first search does not depend
# on a user shell profile.
if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi
if [[ -x "${HOME}/.local/bin/uv" ]]; then
  sudo ln -sfn "${HOME}/.local/bin/uv" /usr/local/bin/uv
  sudo ln -sfn "${HOME}/.local/bin/uvx" /usr/local/bin/uvx
fi
hash -r
command -v uv >/dev/null
uv python install 3.13

# cm-librarian unit tests import psycopg2 at module load (ingest.py).
# The package is only an import dependency for the local suite; tests do not
# open a database.
if ! python3 -c 'import psycopg2' >/dev/null 2>&1; then
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y python3-psycopg2
fi

bun install
