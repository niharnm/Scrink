#!/usr/bin/env bash
# Run mitmproxy with the VeilHeuristicBlocker addon.
# Usage: ./scripts/run_proxy.sh [mode]
#   mode: web (default), proxy, dump, or transparent

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ADDON="$REPO_ROOT/veil_logic.py"

if [[ ! -f "$ADDON" ]]; then
  echo "Addon not found: $ADDON" >&2
  exit 1
fi

# Load config from repo root .env if present
if [[ -f "$REPO_ROOT/.env" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$REPO_ROOT/.env"
  set +a
fi

LISTEN_HOST="${PROXY_LISTEN_HOST:-0.0.0.0}"
LISTEN_PORT="${PROXY_LISTEN_PORT:-8081}"
MODE="${1:-${PROXY_MODE:-web}}"

COMMON_OPTS=(-s "$ADDON" --listen-host "$LISTEN_HOST" --listen-port "$LISTEN_PORT" --set connection_strategy=lazy)

case "$MODE" in
  web)
    exec mitmweb "${COMMON_OPTS[@]}"
    ;;
  proxy)
    exec mitmproxy "${COMMON_OPTS[@]}"
    ;;
  dump)
    exec mitmdump "${COMMON_OPTS[@]}"
    ;;
  transparent)
    exec mitmdump --mode transparent "${COMMON_OPTS[@]}"
    ;;
  *)
    echo "Unknown mode: $MODE (use web, proxy, dump, or transparent)" >&2
    exit 1
    ;;
esac
