#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

data_location="${data_location:-/share/emby}"
config_location="/config/emby"
log() {
  bashio::log.info "$1"
}

log "Updating folder structure and permission : data stored in $data_location"

declare -A directories=(
  ["/emby"]=""
  ["/share/storage/tv"]=""
  ["/share/storage/movies"]=""
  ["$data_location"]=""
  ["$config_location"]=""
)

for dir in "${!directories[@]}"; do
  log "Creating directory: $dir"
  mkdir -p "$dir"
  chown -R "$PUID:$PGID" "$dir"
done

if [ -d /homeassistant/emby ]; then
  log "Migrate previous config location"
  cp -rf /homeassistant/emby/* "$config_location"/
  mv /homeassistant/emby /homeassistant/emby_migrated
  chown -R "$PUID:$PGID" "$config_location"
fi

if [ -f /homeassistant/addons_autoscripts/emby-nas.sh ]; then
  cp -rf /homeassistant/addons_autoscripts/emby-nas.sh "$config_location"/
  mv /homeassistant/addons_autoscripts/emby-nas.sh /homeassistant/addons_autoscripts/emby-nas_migrated.sh
fi

declare -A links=(
  ["/emby/cache"]="$data_location/cache"
  ["/emby/config"]="$config_location"
  ["/emby/data"]="$data_location/data"
  ["/emby/logs"]="$data_location/logs"
  ["/emby/metadata"]="$data_location/metadata"
  ["/emby/plugins"]="$data_location/plugins"
  ["/emby/root"]="$data_location/root"
)

for link in "${!links[@]}"; do
  if [ ! -d "$link" ]; then
    log "Creating link for $link"
    mkdir -p "${links[$link]}"
    chown -R "$PUID:$PGID" "${links[$link]}"
    ln -s "${links[$link]}" "$link"
  fi
done
