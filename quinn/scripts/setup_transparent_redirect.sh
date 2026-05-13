#!/usr/bin/env bash
# Redirect VPN client HTTP(S) traffic to mitmproxy for transparent proxying.
# Requires root. Run on the VPN server. Use with run_proxy.sh transparent.
# Usage: ./scripts/setup_transparent_redirect.sh [enable|disable|status]
# Requires: PROXY_LISTEN_PORT, WG_INTERFACE, and VPN subnet (e.g. 10.0.0.0/24) in .env.

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ -f "$REPO_ROOT/.env" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$REPO_ROOT/.env"
  set +a
fi

WG_INTERFACE="${WG_INTERFACE:-wg0}"
PROXY_LISTEN_PORT="${PROXY_LISTEN_PORT:-8080}"
# Subnet of VPN clients (WireGuard Address range). Must be set for redirect.
VPN_SUBNET="${VPN_SUBNET:-}"

TABLE_NAME="bubble_redirect"

usage() {
  echo "Usage: $0 [enable|disable|status]" >&2
  echo "  enable   - redirect TCP 443 (and 80) from VPN clients to mitmproxy port $PROXY_LISTEN_PORT" >&2
  echo "  disable  - remove redirect rules" >&2
  echo "  status   - show rules" >&2
  echo "Set VPN_SUBNET (e.g. 10.0.0.0/24) and WG_INTERFACE in .env." >&2
  exit 1
}

enable_redirect() {
  if [[ -z "$VPN_SUBNET" ]]; then
    echo "VPN_SUBNET is not set. Set it in .env (e.g. 10.0.0.0/24)." >&2
    exit 1
  fi
  if ! ip link show "$WG_INTERFACE" &>/dev/null; then
    echo "Interface $WG_INTERFACE not found." >&2
    exit 1
  fi
  # Use nftables to redirect traffic from VPN clients (on wg0) to mitmproxy.
  nft add table ip "$TABLE_NAME" 2>/dev/null || true
  nft flush table ip "$TABLE_NAME" 2>/dev/null || true
  nft add chain ip "$TABLE_NAME" prerouting "{ type nat hook prerouting priority dstnat; }"
  nft add rule ip "$TABLE_NAME" prerouting "iifname \"$WG_INTERFACE\" ip saddr $VPN_SUBNET tcp dport 443 redirect to :$PROXY_LISTEN_PORT"
  nft add rule ip "$TABLE_NAME" prerouting "iifname \"$WG_INTERFACE\" ip saddr $VPN_SUBNET tcp dport 80 redirect to :$PROXY_LISTEN_PORT"
  # Block QUIC (HTTP/3 over UDP 443) so browsers fall back to TCP HTTPS, which the proxy can intercept.
  nft add chain ip "$TABLE_NAME" forward_filter "{ type filter hook forward priority filter; }"
  nft add rule ip "$TABLE_NAME" forward_filter "iifname \"$WG_INTERFACE\" ip saddr $VPN_SUBNET udp dport 443 drop"
  echo "Transparent redirect enabled: $VPN_SUBNET TCP 443/80 -> :$PROXY_LISTEN_PORT (QUIC/UDP 443 dropped)"
}

disable_redirect() {
  nft delete table ip "$TABLE_NAME" 2>/dev/null && echo "Redirect disabled." || echo "No table $TABLE_NAME found."
}

status_redirect() {
  if nft list table ip "$TABLE_NAME" &>/dev/null; then
    nft list table ip "$TABLE_NAME"
  else
    echo "Redirect table not loaded."
  fi
}

case "${1:-}" in
  enable)  enable_redirect ;;
  disable) disable_redirect ;;
  status)  status_redirect ;;
  *)       usage ;;
esac
