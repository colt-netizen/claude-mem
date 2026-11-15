#!/usr/bin/env bash
# Start the claude-mem worker on port 37777 and keep it in the foreground.
# Safe to run again: if /api/health already responds, this exits without
# spawning a second process.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

PORT="${CLAUDE_MEM_WORKER_PORT:-37777}"
HEALTH_URL="http://127.0.0.1:${PORT}/api/health"

if curl -sf "$HEALTH_URL" >/dev/null 2>&1; then
  echo "claude-mem worker already healthy on port ${PORT}"
  exit 0
fi

if ! command -v bun >/dev/null 2>&1 && [[ -x "${HOME}/.bun/bin/bun" ]]; then
  sudo ln -sfn "${HOME}/.bun/bin/bun" /usr/local/bin/bun
  hash -r
fi

bun plugin/scripts/worker-service.cjs &
worker_pid=$!

for _ in $(seq 1 90); do
  if curl -sf "$HEALTH_URL" >/dev/null 2>&1; then
    echo "claude-mem worker healthy on port ${PORT} (pid ${worker_pid})"
    wait "$worker_pid"
    exit $?
  fi
  if ! kill -0 "$worker_pid" 2>/dev/null; then
    echo "claude-mem worker exited before /api/health responded" >&2
    exit 1
  fi
  sleep 1
done

echo "claude-mem worker did not become healthy on port ${PORT}" >&2
kill "$worker_pid" 2>/dev/null || true
exit 1
