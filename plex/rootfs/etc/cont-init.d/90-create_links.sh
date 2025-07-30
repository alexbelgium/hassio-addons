#!/usr/bin/with-contenv bashio
set -euo pipefail

PUID="$(bashio::config 'PUID' || echo 0)"
PGID="$(bashio::config 'PGID' || echo 0)"

bashio::log.info "Ensuring Plex library location and symlink ..."

# 1) Ensure base dir exists
install -d -m 0775 /share/plex || mkdir -p /share/plex

# 2) Migrate once if needed
if [ -d /config/Library ] && [ ! -L /config/Library ] && [ ! -e /share/plex/Library ]; then
  bashio::log.info "Migrating /config/Library to /share/plex/Library"
  mv /config/Library /share/plex/
fi

# 3) Ensure target exists
install -d -m 0775 /share/plex/Library || mkdir -p /share/plex/Library

# 4) Ensure symlink /config/Library -> /share/plex/Library
if [ ! -L /config/Library ] || [ "$(readlink -f /config/Library || true)" != "/share/plex/Library" ]; then
  if [ -e /config/Library ] && [ ! -L /config/Library ]; then
    mv /config/Library "/config/Library.bak-$(date +%s)"
  else
    rm -f /config/Library || true
  fi
  ln -sfn /share/plex/Library /config/Library
fi

# 5) Fix ownership and permissions **recursively** so Plex can write its DB
if [ "$PUID" != "0" ] || [ "$PGID" != "0" ]; then
  chown -R "$PUID:$PGID" /share/plex/Library
  chmod -R u+rwX,g+rwX /share/plex/Library
  chmod g+s /share/plex/Library
fi

bashio::log.info "Plex library directory and symlink are ready."
