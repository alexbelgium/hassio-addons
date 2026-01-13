#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

PUID="$(bashio::config 'PUID' || echo 1000)"
PGID="$(bashio::config 'PGID' || echo 1000)"

echo "Creating /data/organizr"
mkdir -p /data/organizr
chown "$PUID:$PGID" /data/organizr

# Only act if the symlink target does not exist
if [[ -d /data/organizr/www/organizr ]] && [[ ! -f /data/organizr/www/organizr/api/data/organizr/default.php ]]; then
    echo "Fix issues in upstream"
    mkdir -p /data/organizr/www/organizr/api/data/organizr
    if [[ -f /data/organizr/www/organizr/api/config/default.php ]]; then
        ln -sf /data/organizr/www/organizr/api/config/default.php /data/organizr/www/organizr/api/data/organizr/default.php
    else
        echo "WARNING: /data/organizr/www/organizr/api/config/default.php does not exist, cannot create symlink"
    fi

    chown -R "$PUID:$PGID" /data/organizr
fi
