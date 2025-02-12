#!/usr/bin/env bashio
# shellcheck shell=bash
set -e
# hadolint ignore=SC2155

# Variables
USER=node
if bashio::config_has.value "RUN_AS"; then
    USER="$(bashio::config "RUN_AS")"
    bashio::log.warning "RUN_AS is set, app will run as $USER"
fi

# Set configuration directory
if [ -d "/home/node/.signalk" ]; then
    rm -r "/home/node/.signalk"
fi
ln -sf /config "/home/node/.signalk"
chown -R "$USER:$USER" /config
chown -R "$USER:$USER" "/home/node/.signalk"

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
done


# Option 2 : set single user for SSL files
for file in ssl-key.pem ssl-cert.pem; do
    if [ -e "/config/.signalk/$file" ]; then
        chown "$USER:$USER" "/config/.signalk/$file"
        chmod 600 "/config/.signalk/$file"
    fi
done

bashio::log.info "Starting application"

sudo -u "$USER" -s /bin/sh -c "/home/node/signalk/startup.sh"
