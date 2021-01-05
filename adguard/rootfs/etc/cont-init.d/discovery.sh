#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant Community Add-on: AdGuard Home
# Sends discovery information to Home Assistant.
# ==============================================================================
declare config

config=$(\
    bashio::var.json \
        host "127.0.0.1" \
        port "^45158" \
)

if bashio::discovery "adguard" "${config}" > /dev/null; then
    bashio::log.info "Successfully send discovery information to Home Assistant."
else
    bashio::log.error "Discovery message to Home Assistant failed!"
fi
