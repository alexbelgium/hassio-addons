#!/bin/bash
# shellcheck shell=bash
#
# Launch coolwsd.
#
# The official image used to ship /start-collabora-online.sh and set it as its
# entrypoint. Since the move to a distroless image that script is gone, so the
# add-on provides its own equivalent. It is invoked as uid 1001 by
# /etc/cont-init.d/99-run.sh and takes everything from the environment, which
# avoids re-quoting extra_params through su.
set -e

# Collabora serves https itself unless the add-on already installed real
# certificates, in which case 99-run.sh exports DONT_GEN_SSL_CERT.
cert_params=""
if [ -z "${DONT_GEN_SSL_CERT:-}" ]; then
    SSL_DIR="/tmp/ssl"
    mkdir -p "${SSL_DIR}/certs/ca" "${SSL_DIR}/certs/servers/localhost" "${SSL_DIR}/certs/tmp"

    openssl genrsa -out "${SSL_DIR}/certs/ca/root.key.pem" 2048
    openssl req -x509 -new -nodes \
        -key "${SSL_DIR}/certs/ca/root.key.pem" -days 9131 \
        -out "${SSL_DIR}/certs/ca/root.crt.pem" \
        -subj "/C=DE/ST=BW/L=Stuttgart/O=Dummy Authority/CN=Dummy Authority"

    openssl genrsa -out "${SSL_DIR}/certs/servers/localhost/privkey.pem" 2048
    openssl req -new -sha256 \
        -key "${SSL_DIR}/certs/servers/localhost/privkey.pem" \
        -out "${SSL_DIR}/certs/tmp/localhost.csr.pem" \
        -subj "/C=DE/ST=BW/L=Stuttgart/O=Dummy Authority/CN=${cert_domain:-localhost}"
    openssl x509 -req -days 9131 \
        -in "${SSL_DIR}/certs/tmp/localhost.csr.pem" \
        -CA "${SSL_DIR}/certs/ca/root.crt.pem" \
        -CAkey "${SSL_DIR}/certs/ca/root.key.pem" -CAcreateserial \
        -out "${SSL_DIR}/certs/servers/localhost/cert.pem"

    cert_params="--o:ssl.cert_file_path=${SSL_DIR}/certs/servers/localhost/cert.pem \
        --o:ssl.key_file_path=${SSL_DIR}/certs/servers/localhost/privkey.pem \
        --o:ssl.ca_file_path=${SSL_DIR}/certs/ca/root.crt.pem"
fi

# Flags mirror the entrypoint of the official image. extra_params is expanded
# last so that add-on options and user overrides win.
# shellcheck disable=SC2086
exec /usr/bin/coolwsd \
    --version \
    --use-env-vars \
    ${cert_params} \
    --o:sys_template_path=/opt/cool/systemplate \
    --o:child_root_path=/opt/cool/child-roots \
    --o:file_server_root_path=/usr/share/coolwsd \
    --o:cache_files.path=/opt/cool/cache \
    --o:logging.color=false \
    --o:stop_on_config_change=true \
    ${extra_params:-}
