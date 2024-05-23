#!/bin/bash
# shellcheck shell=bash

# Avoid original file
if [ -f /etc/caddy/Caddyfile.original ]; then
  rm /etc/caddy/Caddyfile.original
fi

# Get values
source /etc/birdnet/birdnet.conf

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
