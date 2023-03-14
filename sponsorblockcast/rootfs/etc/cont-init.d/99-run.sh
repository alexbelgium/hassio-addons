#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# make directory
mkdir -p /tmp/sponsorblockcast

# Export options as env variables
for var in SBCPOLLINTERVAL SBCSCANINTERVAL SBCCATEGORIES SBCYOUTUBEAPIKEY; do
    if bashio::config.has_value "$var"; then
        export "$var"="$(bashio::config "$var")"
    fi
done

# Starting app
bashio::log.info "Starting app"
/./usr/bin/sponsorblockcast &>/proc/1/fd/1
