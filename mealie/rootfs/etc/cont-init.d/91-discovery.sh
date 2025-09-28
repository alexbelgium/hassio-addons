#!/usr/bin/env bashio
# shellcheck shell=bash

declare config

config=$(
    bashio::var.json \
        host "http://127.0.0.1" \
        port "^$(bashio::addon.port 9001)"
)

if bashio::discovery "mealie" "${config}" > /dev/null; then
    bashio::log.info "Successfully sent discovery information to Home Assistant."
else
    bashio::log.error "Discovery message to Home Assistant failed!"
fi
