#!/usr/bin/env bash
# Extract only the certificate (no private key) from mitmproxy CA for safe
# installation on devices. macOS and some tools reject PEM files that contain
# a private key.
set -e
CONF_DIR="${MITMPROXY_CONF_DIR:-$HOME/.mitmproxy}"
CA_PEM="$CONF_DIR/mitmproxy-ca.pem"
OUT="${1:-}"

if [[ ! -f "$CA_PEM" ]]; then
  echo "Not found: $CA_PEM" >&2
  exit 1
fi

if [[ -n "$OUT" ]]; then
  openssl x509 -in "$CA_PEM" -out "$OUT"
  echo "Certificate only written to: $OUT"
else
  openssl x509 -in "$CA_PEM"
fi
