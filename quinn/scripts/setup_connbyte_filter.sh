#!/usr/bin/env bash
# Certificate-free video blocking via per-connection byte limits.
#
# Instead of MITM-intercepting TLS (which requires a CA cert on every device),
# this uses nftables conntrack byte counting to RST any single HTTPS connection
# through the VPN that exceeds a configurable byte threshold.
#
# How it works:
#   - All TLS passes through untouched (real server certificates, no MITM).
#   - QUIC (UDP 443) is blocked so browsers fall back to TCP HTTPS.
#   - nftables monitors forwarded TCP 443 connections via conntrack.
#   - Once a connection's total bytes exceed CONN_MAX_BYTES, it's killed with
#     a TCP RST in both directions.
#
# Trade-offs vs transparent MITM proxy:
#   + No CA certificate needed on client devices.
#   + Simpler — pure network-level, no mitmproxy required.
#   - Cannot distinguish video from other large responses (images, downloads).
#   - Any single HTTPS connection exceeding the threshold is killed.
#   - Typical 2 MB threshold works well: normal browsing rarely exceeds it,
#     while video reels (2–15 MB) are reliably caught.
#
# Requires root. Run on the VPN server.
# Usage: ./scripts/setup_connbyte_filter.sh [enable|disable|status]

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
VPN_SUBNET="${VPN_SUBNET:-}"
CONN_MAX_BYTES="${CONN_MAX_BYTES:-2000000}"

TABLE_NAME="bubble_connlimit"

usage() {
  echo "Usage: $0 [enable|disable|status]" >&2
  echo "  enable   - RST HTTPS connections exceeding $CONN_MAX_BYTES bytes on $WG_INTERFACE" >&2
  echo "  disable  - remove connection byte limit rules" >&2
  echo "  status   - show current rules and counters" >&2
  echo "" >&2
  echo "Set CONN_MAX_BYTES, VPN_SUBNET, and WG_INTERFACE in .env." >&2
  echo "This does NOT require mitmproxy — blocking is done at the network level." >&2
  exit 1
}

enable_filter() {
  if [[ -z "$VPN_SUBNET" ]]; then
    echo "VPN_SUBNET is not set. Set it in .env (e.g. 10.0.0.0/24)." >&2
    exit 1
  fi
  if [[ "$CONN_MAX_BYTES" -le 0 ]]; then
    echo "CONN_MAX_BYTES must be a positive number (got $CONN_MAX_BYTES)." >&2
    exit 1
  fi
  if ! ip link show "$WG_INTERFACE" &>/dev/null; then
    echo "Interface $WG_INTERFACE not found. Is WireGuard running?" >&2
    exit 1
  fi

  # Ensure IP forwarding is enabled (required for VPN traffic to reach internet).
  sysctl -q net.ipv4.ip_forward=1

  # Build the nftables table.
  nft add table ip "$TABLE_NAME" 2>/dev/null || true
  nft flush table ip "$TABLE_NAME" 2>/dev/null || true

  # --- NAT: masquerade VPN client traffic going out to the internet ---
  nft add chain ip "$TABLE_NAME" postrouting "{ type nat hook postrouting priority srcnat; }"
  nft add rule ip "$TABLE_NAME" postrouting "oifname != \"$WG_INTERFACE\" ip saddr $VPN_SUBNET masquerade"

  # --- Forward chain: QUIC block + connection byte limit ---
  nft add chain ip "$TABLE_NAME" forward "{ type filter hook forward priority filter; policy accept; }"

  # Block QUIC (HTTP/3 over UDP 443) so browsers use TCP HTTPS instead.
  nft add rule ip "$TABLE_NAME" forward \
    "iifname \"$WG_INTERFACE\" ip saddr $VPN_SUBNET udp dport 443 drop"

  # RST HTTPS connections exceeding the byte threshold.
  # ct bytes counts total bytes (both directions) tracked by conntrack.
  # We match in both forwarding directions to ensure a clean RST to both sides.

  # Client → Server direction (outgoing from VPN):
  nft add rule ip "$TABLE_NAME" forward \
    "iifname \"$WG_INTERFACE\" ip saddr $VPN_SUBNET tcp dport 443 ct bytes > $CONN_MAX_BYTES counter reject with tcp reset"

  # Server → Client direction (incoming to VPN):
  nft add rule ip "$TABLE_NAME" forward \
    "oifname \"$WG_INTERFACE\" ip daddr $VPN_SUBNET tcp sport 443 ct bytes > $CONN_MAX_BYTES counter reject with tcp reset"

  echo ""
  echo "Connection byte limit ENABLED."
  echo "  Interface:   $WG_INTERFACE"
  echo "  Subnet:      $VPN_SUBNET"
  echo "  Threshold:   $CONN_MAX_BYTES bytes ($((CONN_MAX_BYTES / 1000)) KB)"
  echo "  QUIC:        blocked (UDP 443)"
  echo "  Masquerade:  enabled for VPN→internet"
  echo ""
  echo "No CA certificate is needed on client devices."
  echo "Any single HTTPS connection exceeding $CONN_MAX_BYTES bytes will be reset."
  echo ""
  echo "NOTE: Disable the transparent redirect if it's active:"
  echo "  sudo ./scripts/setup_transparent_redirect.sh disable"
}

disable_filter() {
  nft delete table ip "$TABLE_NAME" 2>/dev/null \
    && echo "Connection byte limit disabled." \
    || echo "No table $TABLE_NAME found."
  echo ""
  echo "NOTE: If your WireGuard config does not include masquerade/NAT, VPN"
  echo "clients may lose internet access. Re-enable or add masquerade separately."
}

status_filter() {
  if nft list table ip "$TABLE_NAME" &>/dev/null; then
    nft list table ip "$TABLE_NAME"
  else
    echo "Connection byte limit table ($TABLE_NAME) not loaded."
    echo "Enable with: sudo $0 enable"
  fi
}

case "${1:-}" in
  enable)  enable_filter ;;
  disable) disable_filter ;;
  status)  status_filter ;;
  *)       usage ;;
esac
