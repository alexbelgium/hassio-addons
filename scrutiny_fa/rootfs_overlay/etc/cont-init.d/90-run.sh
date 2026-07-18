#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

#########################
# EXPOSE COLLECTOR.YAML #
#########################

if bashio::config.true "expose_collector"; then
    bashio::log.info "collector.yaml exposed in /share/scrutiny"
    mkdir -p /share/scrutiny
    if [ -f /data/config/collector.yaml ] && [ ! -L /data/config/collector.yaml ]; then
        if cp -n /data/config/collector.yaml /share/scrutiny; then
            rm -f /data/config/collector.yaml
        else
            bashio::log.warning "Could not copy /data/config/collector.yaml; keeping the source file"
        fi
    fi
    if [ -f /opt/scrutiny/config/collector.yaml ] && [ ! -L /opt/scrutiny/config/collector.yaml ]; then
        if cp -n /opt/scrutiny/config/collector.yaml /share/scrutiny; then
            rm -f /opt/scrutiny/config/collector.yaml
        else
            bashio::log.warning "Could not copy /opt/scrutiny/config/collector.yaml; keeping the source file"
        fi
    fi
    touch /share/scrutiny/collector.yaml
    ln -sf /share/scrutiny/collector.yaml /data/config || true
    mkdir -p /opt/scrutiny/config
    ln -sf /share/scrutiny/collector.yaml /opt/scrutiny/config/collector.yaml || true
    chmod 755 -R /share/scrutiny
fi

########
# MODE #
########

if [[ "$(bashio::config "Mode")" == Collector ]]; then
    # Clean services
    bashio::log.warning "Collector only mode. WebUI and Influxdb will be disabled"
    rm -rf /etc/services.d/influxdb
    rm -rf /etc/services.d/scrutiny
    rm -rf /etc/services.d/nginx
    sed -i "/wait/d" /etc/services.d/collector-once/run
    sed -i "/scrutiny api not ready/d" /etc/services.d/collector-once/run

    # Check collector
    if bashio::config.has_value "COLLECTOR_API_ENDPOINT"; then
        echo "export COLLECTOR_API_ENDPOINT=$(bashio::config "COLLECTOR_API_ENDPOINT")" >> /env.sh
        sed -i "1a export COLLECTOR_API_ENDPOINT=$(bashio::config "COLLECTOR_API_ENDPOINT")" /etc/services.d/collector-once/run
        if [ -d /var/run/s6/container_environment ]; then printf "%s" "$COLLECTOR_API_ENDPOINT" > /var/run/s6/container_environment/COLLECTOR_API_ENDPOINT; fi
        printf "%s\n" "IN_BACKGROUND=\"$COLLECTOR_API_ENDPOINT\"" >> ~/.bashrc
        bashio::log.info "Using 'COLLECTOR_API_ENDPOINT' $(bashio::config "COLLECTOR_API_ENDPOINT")"
    else
        bashio::exit.nok "Mode is set to 'Collector', but 'COLLECTOR_API_ENDPOINT' is not defined"
    fi
fi
