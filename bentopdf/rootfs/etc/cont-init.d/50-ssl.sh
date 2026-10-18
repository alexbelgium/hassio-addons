#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# Serve HTTPS with the user's certificate from /ssl when `ssl` is enabled,
# otherwise generate a self-signed one under /config/bentopdf/ssl/.

if bashio::config.true 'ssl'; then
    bashio::config.require.ssl
    CERT="/ssl/$(bashio::config 'certfile')"
    KEY="/ssl/$(bashio::config 'keyfile')"
    sed -i "s|ssl_certificate .*;|ssl_certificate     ${CERT};|; s|ssl_certificate_key .*;|ssl_certificate_key ${KEY};|" /etc/nginx/nginx.conf
    bashio::log.info "[50-ssl] Using certificate ${CERT}"
    exit 0
fi

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
