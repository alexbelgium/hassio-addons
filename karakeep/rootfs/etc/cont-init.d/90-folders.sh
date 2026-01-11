#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

bashio::log.info "Creating folders"

mkdir -p \
  /data/cache \
  /data/chrome \
  /share/karakeep/extensions \
  /config/meili

if id chrome &>/dev/null; then
  chown -R chrome:chrome /data/cache /data/chrome
fi
