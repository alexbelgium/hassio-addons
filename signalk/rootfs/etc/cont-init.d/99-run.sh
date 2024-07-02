#!/usr/bin/env bashio
# shellcheck shell=bash
set -e
# hadolint ignore=SC2155

# Variables
USER=node

# Set configuration directory
if [ -d /home/node/.signalk ]; then
    rm -r /home/node/.signalk
fi
ln -sf /config /home/node/.signalk
chown -R node:node /config
chown -R node:node /home/node/.signalk

# Give node user permissions for devices
for group in tty dialout plugdev uucp; do
    if compgen -g | grep -q "$group"; then
        usermod -a -G "$group" "$USER" || true
    fi
done 

bashio::log.info "Starting application"

sudo -u "$USER" -s /bin/sh -c "/home/node/signalk/startup.sh"
