#!/usr/bin/with-contenv bashio

scrutiny-collector-metrics run && bashio::log.info "Local Devices Added" || bashio::log.error "Local Devices Not Added" 
#|| bashio::log.error "Privileged mode is disabled, the addon will stop"
# ; \ s6-svscanctl -t /var/run/s6/services
