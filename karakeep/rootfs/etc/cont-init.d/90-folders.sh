#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

bashio::log.info "Creating folders"

mkdir -p \
  /data/cache \
  /data/chrome \
  /config/meili \
  /usr/src/chrome/extensions

if id chrome &>/dev/null; then
  chown -R chrome:chrome /data/cache /data/chrome /usr/src/chrome/extensions
fi
