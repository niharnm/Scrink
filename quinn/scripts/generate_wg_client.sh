#!/usr/bin/env bash
# generate_wg_client.sh – Create a WireGuard client config, add the peer to the
# server, and drop the .conf file into a web-accessible directory so the user
# can download it by visiting a URL.
#
# Usage:
#   sudo ./scripts/generate_wg_client.sh <name>
#
# Example:
#   sudo ./scripts/generate_wg_client.sh jonathan
#   → creates /var/www/html/wireguard/wg-jonathan.conf
#   → user downloads it from  http://<server>/wireguard/wg-jonathan.conf
#
# Requirements: wg (wireguard-tools), sudo / root

set -euo pipefail

# ─── Configuration ───────────────────────────────────────────────────────────
WG_INTERFACE="${WG_INTERFACE:-wg0}"
WG_CONFIG="/etc/wireguard/${WG_INTERFACE}.conf"
WEB_DIR="${WG_WEB_DIR:-/var/www/html/wireguard}"
DNS="${WG_CLIENT_DNS:-1.1.1.1}"

# ─── Helpers ─────────────────────────────────────────────────────────────────
die()  { echo "ERROR: $*" >&2; exit 1; }
info() { echo "==> $*"; }

# ─── Argument validation ────────────────────────────────────────────────────
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <client-name>" >&2
  echo "  e.g. $0 jonathan" >&2
  exit 1
fi

CLIENT_NAME="$1"

# Sanitise: allow only alphanumeric, dash, underscore
if [[ ! "$CLIENT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  die "Client name must be alphanumeric (with - or _). Got: $CLIENT_NAME"
fi

# Must be root (we need to read/write wg config)
if [[ $EUID -ne 0 ]]; then
  die "Run with sudo:  sudo $0 $CLIENT_NAME"
fi

# ─── Read server info from the live interface ────────────────────────────────
if ! ip link show "$WG_INTERFACE" &>/dev/null; then
  die "Interface $WG_INTERFACE is not up. Start WireGuard first."
fi

SERVER_PUBLIC_KEY="$(wg show "$WG_INTERFACE" public-key)"
SERVER_PORT="$(wg show "$WG_INTERFACE" listen-port)"

# Server Address / subnet from the config file
SERVER_ADDRESS="$(grep -E '^\s*Address\s*=' "$WG_CONFIG" | head -1 | sed 's/.*=\s*//' | xargs)"
SUBNET_PREFIX="$(echo "$SERVER_ADDRESS" | cut -d/ -f1 | rev | cut -d. -f2- | rev)"
# e.g. "10.0.0"

if [[ -z "$SUBNET_PREFIX" ]]; then
  die "Could not determine subnet from $WG_CONFIG (Address = $SERVER_ADDRESS)"
fi

# Detect the server's public IP (for Endpoint).  Override with WG_ENDPOINT env var.
if [[ -n "${WG_ENDPOINT:-}" ]]; then
  SERVER_ENDPOINT="$WG_ENDPOINT"
else
  SERVER_ENDPOINT="$(curl -4 -s --max-time 5 ifconfig.me || true)"
  if [[ -z "$SERVER_ENDPOINT" ]]; then
    die "Could not detect public IP. Set WG_ENDPOINT=<ip-or-hostname> and re-run."
  fi
fi

# ─── Find the next free IP in the /24 ───────────────────────────────────────
# Collect all IPs already assigned (server + peers)
mapfile -t USED_IPS < <(
  # Server's own address
  echo "$SERVER_ADDRESS" | cut -d/ -f1
  # Every AllowedIPs in the config (peers)
  grep -E '^\s*AllowedIPs\s*=' "$WG_CONFIG" | sed 's/.*=\s*//' | tr ',' '\n' | \
    sed 's|/.*||' | xargs -n1
)

# Find the lowest unused host in .2–.254
CLIENT_IP=""
for i in $(seq 2 254); do
  CANDIDATE="${SUBNET_PREFIX}.${i}"
  TAKEN=false
  for u in "${USED_IPS[@]}"; do
    if [[ "$u" == "$CANDIDATE" ]]; then
      TAKEN=true
      break
    fi
  done
  if ! $TAKEN; then
    CLIENT_IP="$CANDIDATE"
    break
  fi
done

if [[ -z "$CLIENT_IP" ]]; then
  die "No free IPs left in ${SUBNET_PREFIX}.0/24"
fi

# ─── Check for duplicate client name ────────────────────────────────────────
CONF_FILE="${WEB_DIR}/wg-${CLIENT_NAME}.conf"
if [[ -f "$CONF_FILE" ]]; then
  die "Config already exists: $CONF_FILE  (remove it first or pick a different name)"
fi

if grep -q "# Client: ${CLIENT_NAME}$" "$WG_CONFIG" 2>/dev/null; then
  die "A peer named '$CLIENT_NAME' already exists in $WG_CONFIG"
fi

# ─── Generate client keys ───────────────────────────────────────────────────
CLIENT_PRIVATE_KEY="$(wg genkey)"
CLIENT_PUBLIC_KEY="$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)"

# ─── Build the client config ────────────────────────────────────────────────
CLIENT_CONF="[Interface]
PrivateKey = ${CLIENT_PRIVATE_KEY}
Address = ${CLIENT_IP}/32
DNS = ${DNS}

[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
Endpoint = ${SERVER_ENDPOINT}:${SERVER_PORT}
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
"

# ─── Write the config to the web directory ───────────────────────────────────
mkdir -p "$WEB_DIR"
echo "$CLIENT_CONF" > "$CONF_FILE"
chmod 644 "$CONF_FILE"

# ─── Add the peer to the server config ───────────────────────────────────────
cat >> "$WG_CONFIG" <<EOF

[Peer]
# Client: ${CLIENT_NAME}
PublicKey = ${CLIENT_PUBLIC_KEY}
AllowedIPs = ${CLIENT_IP}/32
EOF

# Hot-reload: add the peer to the running interface without restarting
wg set "$WG_INTERFACE" peer "$CLIENT_PUBLIC_KEY" allowed-ips "${CLIENT_IP}/32"

# ─── Summary ────────────────────────────────────────────────────────────────
info "Client '${CLIENT_NAME}' created"
info "  VPN IP:     ${CLIENT_IP}"
info "  Config:     ${CONF_FILE}"
info "  Download:   http://${SERVER_ENDPOINT}/wireguard/wg-${CLIENT_NAME}.conf"
echo ""

# Show QR code if qrencode is available (handy for iOS)
if command -v qrencode &>/dev/null; then
  info "Scan this QR code in the WireGuard iOS/Android app:"
  echo ""
  qrencode -t ansiutf8 < "$CONF_FILE"
else
  info "Tip: install qrencode to show a scannable QR code:"
  info "  apt install qrencode   # then re-run"
fi
