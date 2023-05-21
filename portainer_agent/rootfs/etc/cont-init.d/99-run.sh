#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# ==============================================================================
# Home Assistant Community Add-on: portainer_agent
# Runs some initializations for portainer_agent
# ==============================================================================
bashio::require.unprotected

# Wait for transmission to become available
bashio::net.wait_for 9001 localhost 50

# Launch app
cd /app || true
./agent "$PORTAINER_AGENT_ARGS"
