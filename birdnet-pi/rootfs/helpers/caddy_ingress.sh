#!/bin/bash
# shellcheck shell=bash

# Get values
set +u
# shellcheck disable=SC1091
source /etc/birdnet/birdnet.conf

# Nothing to do if the ingress site is already there. This script runs both from
# cont-init and from update_caddyfile.sh, and a duplicate ":8082" site address
# makes caddy refuse to start.
if grep -qE '^[[:space:]]*:8082[[:space:]]*\{' /etc/caddy/Caddyfile 2> /dev/null; then
    exit 0
fi

# Create ingress configuration for Caddyfile
cat << EOF >> /etc/caddy/Caddyfile
:8082 {
  root * ${EXTRACTED}
  file_server browse
  handle /By_Date/* {
    file_server browse
  }
  handle /Charts/* {
    file_server browse
  }
  reverse_proxy /stream localhost:8000
  php_fastcgi unix//run/php/php-fpm.sock
  reverse_proxy /log* localhost:8080
  reverse_proxy /stats* localhost:8501
  reverse_proxy /terminal* localhost:8888
}
EOF
