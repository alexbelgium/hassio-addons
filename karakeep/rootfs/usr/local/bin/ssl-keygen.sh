#!/command/with-contenv bashio
# shellcheck shell=bash

set -e

# Check for required arguments
if [ $# -ne 2 ]; then
  bashio::log.error "[ssl-keygen.sh] missing: <certfile> <keyfile>"
  exit 1
fi

certfile="$1"
keyfile="$2"

[ -f "$certfile" ] && rm -f "$certfile"
[ -f "$keyfile" ] && rm -f "$keyfile"

mkdir -p "$(dirname "$certfile")" && mkdir -p "$(dirname "$keyfile")"

if ! hostname="$(bashio::info.hostname 2> /dev/null)" || [ -z "$hostname" ]; then
  hostname="homeassistant"
fi
tmp_openssl_cfg=$(mktemp)
trap 'rm -f "$tmp_openssl_cfg"' EXIT

cat > "$tmp_openssl_cfg" <<EOF
[req]
default_bits       = 4096
prompt             = no
default_md         = sha256
req_extensions     = req_ext
distinguished_name = dn

[dn]
CN = ${hostname}.local

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = ${hostname}.local
EOF

if ! openssl req -x509 -nodes -days 3650 \
    -newkey rsa:4096 \
    -keyout "$keyfile" \
    -out "$certfile" \
    -config "$tmp_openssl_cfg" \
    -extensions req_ext; then

  # Certificate gen failed
  bashio::log.error "OpenSSL certificate generation failed"
  exit 1
fi

bashio::log.info "New self-signed certificate generated"