#!/usr/bin/env bashio
# shellcheck shell=bash
set -e
# hadolint ignore=SC2155

# Variables
USER=node

# Set configuration directory
if [ -d "/home/$USER/.signalk" ]; then
    rm -r "/home/$USER/.signalk"
fi
ln -sf /config "/home/$USER/.signalk"
chown -R "$USER:$USER" /config
chown -R "$USER:$USER" "/home/$USER/.signalk"

# Define permissions for /dev/ttyUSB
for device in /dev/ttyUSB /dev/ttyUSB0 /dev/ttyUSB1; do
    if [ -e "$device" ]; then
        sudo usermod -a -G root node || true
    fi
done

bashio::log.info "Starting application"

sudo -Eu "$USER" -s /bin/bash -c "/home/node/signalk/startup.sh"
