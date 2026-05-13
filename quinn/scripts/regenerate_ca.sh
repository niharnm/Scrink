#!/usr/bin/env bash
# Regenerate the mitmproxy CA. Stop the proxy, run this, then start the proxy again.
# Clients will need to install the new CA (run ./scripts/export_ca.sh after restarting).

set -e
CONF_DIR="${MITMPROXY_CONF_DIR:-$HOME/.mitmproxy}"

if [[ ! -d "$CONF_DIR" ]]; then
  echo "No mitmproxy config dir at $CONF_DIR; nothing to regenerate." >&2
  exit 0
fi

# Remove CA/cert files so mitmproxy creates a fresh CA on next start
rm -f "$CONF_DIR"/mitmproxy-ca.pem \
      "$CONF_DIR"/mitmproxy-ca-cert.pem \
      "$CONF_DIR"/mitmproxy-ca-cert.pem.chain \
      "$CONF_DIR"/mitmproxy-dashboard-ca.pem \
      "$CONF_DIR"/mitmproxy-dashboard-ca-cert.pem \
      "$CONF_DIR"/mitmproxy-dashboard-ca-cert.pem.chain \
      "$CONF_DIR"/mitmproxy-dhparam.pem 2>/dev/null || true

echo "CA files removed from $CONF_DIR"
echo "1. Start the proxy again: ./scripts/run_proxy.sh [transparent|web|proxy|dump]"
echo "2. Export the new CA for clients: ./scripts/export_ca.sh"
echo "3. Reinstall the new CA on each client (MacBook, etc.)."
