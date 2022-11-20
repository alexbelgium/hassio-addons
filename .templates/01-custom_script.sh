#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

slug="${HOSTNAME#*-}"
bashio::log.info "Execute /config/${slug}.sh if existing"

if [ -f /config/"${slug}".sh ]; then
    bashio::log.info "... script found, executing"
    chmod +x /config/"${slug}".sh
    /./config/"${slug}".sh
else
    bashio::log.info "... no script found"
fi

