#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# ==============================================================================
# Home Assistant Add-on: Omni Tools
# Starts omni-tools
# ==============================================================================

# Start omni-tools container content
bashio::log.info "Starting application"
/./docker-entrypoint.sh & true

# Wait for app to become available
bashio::net.wait_for 8096 localhost 900

# Start nginx
bashio::log.info "Starting NGinx..."
exec nginx &>/proc/1/fd/1
