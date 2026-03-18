#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Generate a self-signed TLS certificate for HTTPS access on LAN.
# The cert is stored under /config/bentopdf/ssl/ so it persists across restarts.

SSL_DIR=/config/bentopdf/ssl
CERT="${SSL_DIR}/cert.pem"
KEY="${SSL_DIR}/key.pem"

if [ ! -f "${CERT}" ] || [ ! -f "${KEY}" ]; then
    echo "[50-ssl] Generating self-signed TLS certificate..."
    mkdir -p "${SSL_DIR}"
    openssl req -x509 -nodes -newkey rsa:2048 \
        -keyout "${KEY}" \
        -out "${CERT}" \
        -days 3650 \
        -subj "/CN=homeassistant.local" \
        -addext "subjectAltName=DNS:homeassistant.local,DNS:localhost,IP:127.0.0.1"
    echo "[50-ssl] Certificate generated at ${CERT}"
else
    echo "[50-ssl] TLS certificate already exists, skipping generation."
fi
