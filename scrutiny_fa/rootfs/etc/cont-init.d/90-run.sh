#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

########
# MODE #
########

if [[ "$(bashio::config "Mode")" == Collector ]]; then
    # Clean services
    bashio::log.warning "Collector only mode. WebUI and Influxdb will be disabled"
    rm -r /etc/services.d/influxdb
    rm -r /etc/services.d/scrutiny
    rm -r /etc/services.d/nginx
    sed -i "/wait/d" /etc/services.d/collector-once/run
    sed -i "/scrutiny api not ready/d" /etc/services.d/collector-once/run

    # Check collector
    if bashio::config.has_value "COLLECTOR_API_ENDPOINT"; then
      echo "export COLLECTOR_API_ENDPOINT=$(bashio::config "COLLECTOR_API_ENDPOINT")" >> /env.sh
      sed -i "1a export COLLECTOR_API_ENDPOINT=$(bashio::config "COLLECTOR_API_ENDPOINT")" /etc/services.d/collector-once/run
      bashio::log.info "Using 'COLLECTOR_API_ENDPOINT' $(bashio::config "COLLECTOR_API_ENDPOINT")"
    else
      bashio::exit.nok "Mode is set to 'Collector', but 'COLLECTOR_API_ENDPOINT' is not defined"
    fi
fi
