#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# ==============================================================================
# Home Assistant Add-on: Omni Tools
# Starts omni-tools
# ==============================================================================

# Start omni-tools container content
bashio::log.info "Starting application"
# Backgrounded on purpose. ha_entrypoint.sh runs every cont-init.d script in the
# foreground, so launching nginx here in the foreground never lets it reach the
# terminate() handler that forwards SIGTERM on shutdown -- the add-on then could
# not be stopped at all (#3049). Backgrounded, this script returns, nginx is
# reparented to the entrypoint as PID 1, and terminate() signals it directly.
# Requires init: false in config.yaml, which is what makes the entrypoint PID 1.
/./docker-entrypoint.sh nginx -g "daemon off;" &> /proc/1/fd/1 &
