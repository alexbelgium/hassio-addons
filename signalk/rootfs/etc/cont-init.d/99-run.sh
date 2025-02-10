#!/usr/bin/env bashio
# shellcheck shell=bash
set -e
# hadolint ignore=SC2155

# Set configuration directory
mkdir -p /config/.signalk
if [ -d "/home/node/.signalk" ]; then
    if [ -n "$(find /home/node/.signalk -mindepth 1 -print -quit 2>/dev/null)" ]; then
        cp -r /home/node/.signalk/* /config/.signalk/
    fi
    rm -rf "/home/node/.signalk"
fi
ln -sf /config/.signalk "/home/node/.signalk"

# Set single user for SSL files
for file in ssl-key.pem ssl-cert.pem; do
    if [ -e "/config/.signalk/$file" ]; then
        chown "$(id -u):$(id -g)" "/config/.signalk/$file"
        chmod 600 "/config/.signalk/$file"
    fi
done

bashio::log.info "Starting application"
exec /home/node/signalk/startup.sh
