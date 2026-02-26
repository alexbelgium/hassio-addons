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
# Use sed instead of usermod/groupmod to avoid hangs in container environments
# (usermod can block indefinitely due to lock contention, NSS, or PAM issues)
echo "... setting permissions for node user"
sed -i 's/^\(node:[^:]*:\)[0-9]*:[0-9]*/\10:0/' /etc/passwd
sed -i 's/^\(node:[^:]*:\)[0-9]*/\10/' /etc/group

# Ensure 600 for SSL files
echo "... specifying security files permissions"
for file in ssl-key.pem ssl-cert.pem security.json; do
    if [ -e "/config/$file" ]; then
        chmod 600 "/config/$file"
    fi
done

# Rebuild npm dependency bindings on version change
current_version="$(bashio::addon.version)"
if [[ ! -f /data/version || "$current_version" != "$(cat /data/version)" ]]; then
    if [[ -f /config/package.json ]]; then
        bashio::log.info "Update detected, rebuilding native node deps"
        cd /config
        npm rebuild
        echo "$current_version" > /data/version
    else
        bashio::log.warning "Update detected, but /config/package.json is missing; skipping npm rebuild"
    fi
fi


bashio::log.info "Starting application"
sudo -u "$USER" -s /bin/sh -c "/home/node/signalk/startup.sh"
