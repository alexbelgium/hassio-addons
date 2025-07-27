#!/usr/bin/env bashio
# shellcheck shell=bash
set -e
# hadolint ignore=SC2155

# Set configuration directory
if [ -d "/home/node/.signalk" ]; then
    rm -r "/home/node/.signalk"
fi

# Variables
USER=node
echo "... creating symlinks and checking permissions"
ln -sf /config "/home/node/.signalk"
chown -R "$USER:$USER" /config

# Set permissions
echo "... setting permissions for node user"
usermod -o -u 0 node
groupmod -o -g 0 node

# Ensure 600 for SSL files
echo "... specifying security files permissions"
for file in ssl-key.pem ssl-cert.pem security.json; do
    if [ -e "/config/$file" ]; then
        chmod 600 "/config/$file"
    fi
done

bashio::log.info "Starting application"
sudo -u "$USER" -s /bin/sh -c "/home/node/signalk/startup.sh"
