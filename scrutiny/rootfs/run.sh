#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# wait for scrutiny to load
bashio::net.wait_for 8080

#####################
# ADD LOCAL DEVICES #
#####################

# search for local devices
scrutiny-collector-metrics run >/dev/null && bashio::log.info "Local Devices Added" || bashio::log.error "Local Devices Not Added"
