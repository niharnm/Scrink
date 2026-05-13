#!/usr/bin/env bash
# Print paths to mitmproxy CA certs so clients can install them.
# Run after starting mitmproxy at least once (it generates the CA).

set -e
# Standard mitmproxy CA location (can be overridden by MITMPROXY_CONF_DIR)
CONF_DIR="${MITMPROXY_CONF_DIR:-$HOME/.mitmproxy}"

if [[ ! -d "$CONF_DIR" ]]; then
  echo "mitmproxy config dir not found: $CONF_DIR" >&2
  echo "Start mitmproxy once (e.g. ./scripts/run_proxy.sh) to generate the CA." >&2
  exit 1
fi

# mitmproxy-dashboard-ca.pem is the cert; mitmproxy-ca.pem is the same in older naming.
# Prefer the PEM that clients can add to system trust.
for name in mitmproxy-dashboard-ca.pem mitmproxy-ca.pem; do
  if [[ -f "$CONF_DIR/$name" ]]; then
    echo "$CONF_DIR/$name"
    exit 0
  fi
done

echo "No CA PEM found in $CONF_DIR" >&2
exit 1
