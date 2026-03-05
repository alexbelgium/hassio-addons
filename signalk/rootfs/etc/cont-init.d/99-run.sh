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
if id "$USER" &>/dev/null; then
    current_uid="$(id -u "$USER")"
    current_gid="$(id -g "$USER")"

    if [[ "$current_uid" != "0" ]]; then
        if ! usermod -o -u 0 "$USER"; then
            bashio::log.warning "Failed to set UID 0 for $USER; continuing with UID $current_uid"
        fi
    fi

    if [[ "$current_gid" != "0" ]]; then
        if ! groupmod -o -g 0 "$USER"; then
            bashio::log.warning "Failed to set GID 0 for $USER; continuing with GID $current_gid"
        fi
    fi
else
    bashio::log.warning "User $USER does not exist; continuing without UID/GID remap"
fi

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
