#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# ==============================================================================
# Home Assistant Add-on: Omni Tools
# Starts omni-tools
# ==============================================================================

# Start omni-tools container content
bashio::log.info "Starting application"
/./docker-entrypoint.sh nginx -g daemon &>/proc/1/fd/1
