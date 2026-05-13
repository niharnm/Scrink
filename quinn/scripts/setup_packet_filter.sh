#!/usr/bin/env bash
# Configure nftables on the WireGuard interface to drop inner packets by length.
# Requires root. Run on the VPN server.
# Usage: ./scripts/setup_packet_filter.sh [enable|disable|status]

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
PACKET_MAX_BYTES="${PACKET_MAX_BYTES:-0}"
TABLE_NAME="bubble_filter"
CHAIN_NAME="wg_filter"

usage() {
  echo "Usage: $0 [enable|disable|status]" >&2
  echo "  enable   - add nftables rules to drop packets larger than PACKET_MAX_BYTES on $WG_INTERFACE" >&2
  echo "  disable  - remove bubble filter table" >&2
  echo "  status   - show current rules" >&2
  echo "Set PACKET_MAX_BYTES and WG_INTERFACE in .env or config.example.env." >&2
  exit 1
}

enable_filter() {
  if [[ "$PACKET_MAX_BYTES" -le 0 ]]; then
    echo "PACKET_MAX_BYTES is $PACKET_MAX_BYTES; set to a positive value (e.g. 9000) in .env to enable." >&2
    exit 1
  fi
  if ! ip link show "$WG_INTERFACE" &>/dev/null; then
    echo "Interface $WG_INTERFACE not found." >&2
    exit 1
  fi
  # Create table and chains. We only apply length check to traffic on the WG interface.
  nft add table inet "$TABLE_NAME" 2>/dev/null || true
  nft flush table inet "$TABLE_NAME" 2>/dev/null || true
  nft add chain inet "$TABLE_NAME" input_chain "{ type filter hook input priority filter - 10; }"
  nft add chain inet "$TABLE_NAME" output_chain "{ type filter hook output priority filter - 10; }"
  # Only touch traffic on WG interface; drop packets larger than PACKET_MAX_BYTES
  nft add rule inet "$TABLE_NAME" input_chain "iifname != \"$WG_INTERFACE\" accept"
  nft add rule inet "$TABLE_NAME" input_chain "length > $PACKET_MAX_BYTES drop"
  nft add rule inet "$TABLE_NAME" output_chain "oifname != \"$WG_INTERFACE\" accept"
  nft add rule inet "$TABLE_NAME" output_chain "length > $PACKET_MAX_BYTES drop"
  echo "Packet filter enabled: dropping packets on $WG_INTERFACE with length > $PACKET_MAX_BYTES bytes"
}

disable_filter() {
  nft delete table inet "$TABLE_NAME" 2>/dev/null && echo "Packet filter disabled." || echo "No table $TABLE_NAME found."
}

status_filter() {
  if nft list table inet "$TABLE_NAME" &>/dev/null; then
    nft list table inet "$TABLE_NAME"
  else
    echo "Packet filter table not loaded."
  fi
}

case "${1:-}" in
  enable)  enable_filter ;;
  disable) disable_filter ;;
  status)  status_filter ;;
  *)       usage ;;
esac
