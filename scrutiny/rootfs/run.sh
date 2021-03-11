#!/usr/bin/with-contenv bashio

# wait for scrutiny to load
bashio::net.wait_for 8080

# search for local devices
scrutiny-collector-metrics run >/dev/null && bashio::log.info "Local Devices Added" || bashio::log.error "Local Devices Not Added" 
