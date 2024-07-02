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

# Define permissions for /dev/ttyUSB
for device in /dev/ttyUSB /dev/ttyUSB0 /dev/ttyUSB1; do
    if [ -f "$device" ]; do
        usermod -a -G "$(stat -c "%G" "$device")" $USER
        chmod 777 "$device"
        chown "$USER" "$device"
    done
done

bashio::log.info "Starting application"

sudo -u "$USER" -s /bin/sh -c "/home/node/signalk/startup.sh"
