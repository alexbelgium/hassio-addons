#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant Community Add-on: AdGuard Home
# Runs the AdGuard Home server
# ==============================================================================
declare -a options

bashio::log.info "Starting AdGuard Home server..."

options+=(--port 45158)
options+=(--host 127.0.0.1)
options+=(--work-dir /data/adguard)
options+=(--no-check-update)

if bashio::debug; then
    option+=(--verbose)
fi

# RUN AdGuard Home server
cd /opt/AdGuardHome || exit
exec ./AdGuardHome "${options[@]}"
