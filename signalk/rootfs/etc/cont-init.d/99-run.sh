#!/usr/bin/env bashio
# shellcheck shell=bash
set -e
# hadolint ignore=SC2155

# Set configuration directory
if [ -d /home/node/.signalk ]; then
    rm -r /home/node/.signalk
fi
ln -sf /config /home/node/.signalk
chown -R node:node /config
chown -R node:node /home/node/.signalk

bashio::log.info "Starting application"

sudo -u node -s /bin/sh -c "/home/node/signalk/startup.sh"
