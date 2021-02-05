#!/usr/bin/with-contenv bashio
export PUID=$(bashio::config 'PUID')
export PGID=$(bashio::config 'PGID')
bashio::log.info "Set PUID: "$PUID
bashio::log.info "Set PGID: "$PGID
