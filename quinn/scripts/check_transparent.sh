#!/usr/bin/env bash
# Quick checks for bubble setup (both modes).
# Run on the server. No root needed for status checks.

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ -f "$REPO_ROOT/.env" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$REPO_ROOT/.env"
  set +a
fi

PROXY_LISTEN_PORT="${PROXY_LISTEN_PORT:-8080}"
WG_INTERFACE="${WG_INTERFACE:-wg0}"
VPN_SUBNET="${VPN_SUBNET:-}"
CONN_MAX_BYTES="${CONN_MAX_BYTES:-2000000}"

# Detect which mode is active.
HAS_CONNLIMIT=false
HAS_REDIRECT=false
sudo nft list table ip bubble_connlimit &>/dev/null 2>&1 && HAS_CONNLIMIT=true
sudo nft list table ip bubble_redirect &>/dev/null 2>&1 && HAS_REDIRECT=true

echo "=== WireGuard interface: $WG_INTERFACE ==="
if ip link show "$WG_INTERFACE" &>/dev/null; then
  echo "  OK: interface exists."
else
  echo "  NOT FOUND. Is WireGuard running? Set WG_INTERFACE in .env."
fi

echo ""
echo "=== Active mode ==="

if $HAS_CONNLIMIT; then
  echo "  Mode: CONNBYTE FILTER (Option A — no CA cert needed)"
  echo ""
  echo "--- Connection byte limit rules ---"
  sudo nft list table ip bubble_connlimit
  echo ""
  echo "--- Counters show how many connections have been reset. ---"

  if $HAS_REDIRECT; then
    echo ""
    echo "  WARNING: Transparent redirect is also active. You probably want to disable it:"
    echo "    sudo ./scripts/setup_transparent_redirect.sh disable"
  fi

  echo ""
  echo "=== Device checklist (Option A) ==="
  echo "  - Device is connected to this server via WireGuard (VPN)."
  echo "  - VPN is used for internet (default route or all traffic)."
  echo "  - NO proxy settings needed on the device."
  echo "  - NO CA certificate needed on the device."
  echo "  - Any single HTTPS connection exceeding $CONN_MAX_BYTES bytes (~$((CONN_MAX_BYTES / 1000)) KB) will be reset."
  echo ""
  echo "To test: open Instagram on the device. Images should load; reels/videos should stall."

elif $HAS_REDIRECT; then
  echo "  Mode: TRANSPARENT MITM PROXY (Option B — requires CA cert)"
  echo ""
  echo "--- Redirect rules ---"
  sudo nft list table ip bubble_redirect
  echo ""
  echo "--- Proxy status ---"
  if ss -ltn 2>/dev/null | grep -q ":$PROXY_LISTEN_PORT "; then
    PROC=$(ss -ltnp 2>/dev/null | grep ":$PROXY_LISTEN_PORT " | head -1 || true)
    if echo "$PROC" | grep -q mitmdump; then
      echo "  OK: mitmdump is listening on :$PROXY_LISTEN_PORT (transparent mode)."
    elif echo "$PROC" | grep -q mitm; then
      echo "  WRONG MODE: mitmproxy/mitmweb on :$PROXY_LISTEN_PORT (need mitmdump for transparent)."
      echo "  Stop it, then run: ./scripts/run_proxy.sh transparent"
    else
      echo "  Port $PROXY_LISTEN_PORT in use. Ensure: ./scripts/run_proxy.sh transparent"
    fi
  else
    echo "  Nothing listening on :$PROXY_LISTEN_PORT. Start: ./scripts/run_proxy.sh transparent"
  fi

  echo ""
  echo "=== Device checklist (Option B) ==="
  echo "  - Device is connected to this server via WireGuard (VPN)."
  echo "  - VPN is used for internet (default route or all traffic)."
  echo "  - No proxy settings needed on the device (redirect is automatic)."
  echo "  - Install and trust the mitmproxy CA cert on the device."
  echo ""
  echo "To test: open Instagram. Blocked requests appear in proxy log; reels won't play."

else
  echo "  NONE — no filtering is active."
  echo ""
  echo "  Option A (no cert): sudo ./scripts/setup_connbyte_filter.sh enable"
  echo "  Option B (MITM):    sudo ./scripts/setup_transparent_redirect.sh enable"
  echo "                      then: ./scripts/run_proxy.sh transparent"
fi
