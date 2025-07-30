#!/usr/bin/with-contenv bashio
set -euo pipefail

# --- Config ---
PUID="$(bashio::config 'PUID' || echo 0)"
PGID="$(bashio::config 'PGID' || echo 0)"

bashio::log.info "Ensuring Plex library location and symlink ..."

# 1) Ensure base dir exists
install -d -m 0775 /share/plex

# 2) If a real /config/Library exists and /share/plex/Library doesn't, migrate it once
if [ -d /config/Library ] && [ ! -L /config/Library ] && [ ! -e /share/plex/Library ]; then
  bashio::log.info "Migrating /config/Library to /share/plex/Library"
  mv /config/Library /share/plex/   # results in /share/plex/Library
fi

# 3) Ensure target exists (in case there was nothing to migrate)
install -d -m 0775 /share/plex/Library

# 4) Ensure symlink /config/Library -> /share/plex/Library
if [ ! -L /config/Library ] || [ "$(readlink -f /config/Library || true)" != "/share/plex/Library" ]; then
  # If a leftover dir/file exists at /config/Library, back it up instead of deleting
  if [ -e /config/Library ] && [ ! -L /config/Library ]; then
    TS="$(date +%s)"
    bashio::log.warning "Found non-symlink at /config/Library; backing up to /config/Library.bak-${TS}"
    mv /config/Library "/config/Library.bak-${TS}"
  else
    rm -f /config/Library || true
  fi
  ln -sfn /share/plex/Library /config/Library
fi

# 5) Ownership & top-level perms (independent checks; avoid recursive 777)
if [ "$PUID" != "0" ] || [ "$PGID" != "0" ]; then
  chown "$PUID:$PGID" /share/plex /share/plex/Library
  # 2775 keeps group for new items created inside
  chmod 2775 /share/plex /share/plex/Library
fi

bashio::log.info "Plex library directory and symlink are ready."
