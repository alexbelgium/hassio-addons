#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

# Migrate files for new config location
slug="fireflyiii_fints_importer"
if [ -d "/homeassistant/addons_config/$slug" ] && [ ! -f "/homeassistant/addons_config/$slug/migrated" ]; then
    bashio::log.warning "Migrating configurations"
    # Self-referencing link left by previous versions
    if [ -L "/homeassistant/addons_config/$slug/$slug" ]; then rm "/homeassistant/addons_config/$slug/$slug"; fi
    mkdir -p /config/configurations
    mv "/homeassistant/addons_config/$slug"/* /config/configurations/ || true
    echo "Migrated to internal config folder accessible at /addon_configs/xxx_$slug/configurations" > "/homeassistant/addons_config/$slug/migrated"
fi

if [ -f "/homeassistant/addons_autoscripts/fireflyiii-fints-importer.sh" ]; then
    bashio::log.warning "Migrating autoscript"
    mv /homeassistant/addons_autoscripts/fireflyiii-fints-importer.sh /config/ || true
fi
