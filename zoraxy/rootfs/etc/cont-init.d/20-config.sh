#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

#############################################
# Prepare persistent storage under /config  #
#############################################

# Zoraxy stores its database, configuration, logs and plugins relative to its
# working directory. The Dockerfile patched the upstream entrypoint to use
# /config (mapped to addon_config) so the data survives add-on updates.
mkdir -p /config /config/plugin /config/conf /config/log /config/tmp

bashio::log.info "Zoraxy data directory: /config"
