#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# make directory

mkdir -p /tmp/castsponsorskip

# Export options as env variables
for var in CSS_CATEGORIES CSS_DISCOVER_INTERVAL CSS_PAUSED_INTERVAL CSS_PLAYING_INTERVAL CSS_YOUTUBE_API_KEY CSS_MUTE_ADS; do
  if bashio::config.has_value "$var"; then
    export "$var"="$(bashio::config "$var")"
  fi
done

# Starting app
bashio::log.info "Starting app"
./castsponsorskip
