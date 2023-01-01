#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

slug="${HOSTNAME#*-}"
bashio::log.info "Execute /config/addons_autoscripts/${slug}.sh if existing"

mkdir -p /config/addons_autoscripts

# Migrate scripts
if [ -f /config/"${slug}".sh ]; then
    mv -f /config/"${slug}".sh /config/addons_autoscripts/"${slug}".sh
fi

# Execute scripts
if [ -f /config/addons_autoscripts/"${slug}".sh ]; then
    bashio::log.info "... script found, executing"
    chmod +x /config/addons_autoscripts/"${slug}".sh
    /./config/addons_autoscripts/"${slug}".sh
else
    bashio::log.info "... no script found"
fi

