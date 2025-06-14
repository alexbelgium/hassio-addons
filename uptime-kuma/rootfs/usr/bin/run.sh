#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Create directories if needed
mkdir -p /data/uptime-kuma

# Make our storage persistent
if [ ! -d /app/data ]; then
    bashio::log.info "Setting up persistent data directory..."
    mkdir -p /app/data
fi

if [ ! -L /app/data ]; then
    bashio::log.info "Linking persistent data directory..."
    rm -rf /app/data
    ln -s /data/uptime-kuma /app/data
fi

# SSL Configuration
if bashio::config.true 'ssl'; then
    certfile=$(bashio::config 'certfile')
    keyfile=$(bashio::config 'keyfile')

    if [ -f "/ssl/$certfile" ] && [ -f "/ssl/$keyfile" ]; then
        bashio::log.info "SSL enabled - using provided certificate"
        export UPTIME_KUMA_SSL_CERT="/ssl/$certfile"
        export UPTIME_KUMA_SSL_KEY="/ssl/$keyfile"
    else
        bashio::log.error "SSL enabled but certificate or key not found"
        exit 1
    fi
fi

# Proxy configuration
if bashio::config.has_value 'proxy_host'; then
    # Declare variables
    declare proxy_host
    declare proxy_port

    # Set and export proxy settings
    proxy_host=$(bashio::config 'proxy_host')
    proxy_port=$(bashio::config 'proxy_port')
    export UPTIME_KUMA_PROXY_HOST="${proxy_host}"
    export UPTIME_KUMA_PROXY_PORT="${proxy_port}"

    if bashio::config.true 'proxy_ssl'; then
        export UPTIME_KUMA_PROXY_SSL="true"
    fi
fi

# Basic auth configuration
if bashio::config.has_value 'username'; then
    # Declare variables
    declare auth_user
    declare auth_pass

    # Set and export auth settings
    auth_user=$(bashio::config 'username')
    auth_pass=$(bashio::config 'password')
    export UPTIME_KUMA_BASIC_AUTH_USER="${auth_user}"
    export UPTIME_KUMA_BASIC_AUTH_PASS="${auth_pass}"
fi

bashio::log.info "Starting Uptime Kuma..."
cd /app || bashio::exit.nok "Could not change to app directory"

# Start the application
exec node server/server.js
