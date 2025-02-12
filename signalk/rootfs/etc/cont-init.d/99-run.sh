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
if bashio::config.true "RUN_AS_ROOT"; then
    USER="root"
    HOMEDIR="/root"
    bashio::log.warning "RUN_AS is set, app will run as $USER"
    ln -sf /config "/root/.signalk"
else
    HOMEDIR="/home/node"
    ln -sf /config "/home/node/.signalk"
fi
chown -R "$USER:$USER" /config
ln -sf /config "$HOMEDIR/.signalk"
chown -R "$USER:$USER" "$HOMEDIR"
chown -R "$USER:$USER" "$HOMEDIR/.signalk"

# Option 1 : define permissions for /dev/ttyUSB
for device in /dev/ttyUSB /dev/ttyUSB0 /dev/ttyUSB1; do
    if [ -e "$device" ]; then
        # Check if 'node' is already in the 'root' group before modifying
        if ! groups node | grep -q '\broot\b'; then
            sudo usermod -a -G root node || true
            echo "User 'node' added to group 'root'."
        else
            echo "User 'node' is already in group 'root'."
        fi
    fi
done || true


# Option 2 : set single user for SSL files
for file in ssl-key.pem ssl-cert.pem security.json; do
    if [ -e "/config/$file" ]; then
        chmod 600 "/config/$file"
    fi
done

bashio::log.info "Starting application"
sudo -u "$USER" -s /bin/sh -c "/home/node/signalk/startup.sh"
