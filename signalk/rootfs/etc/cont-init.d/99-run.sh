#!/usr/bin/env bashio
# shellcheck shell=bash
set -e
# hadolint ignore=SC2155

# Set configuration directory
mkdir -p /config/.signalk
if [ -d "/home/node/.signalk" ]; then
    rm -r "/home/node/.signalk"
fi
ln -sf /config "/home/node/.signalk"

# Set single user for ssl files
for files in ssl-key.pem ssl-cert.pem; do
    if [ -f /config/.signalk/"$files" ]; then
        chmod -600 /config/.signalk/"$files"
    fi
done

bashio::log.info "Starting application"
/./home/node/signalk/startup.sh
