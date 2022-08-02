#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
 
if [ -f /config/addons_config/nextcloud/*.sh ]; then
bashio::log.info "Scripts found in /config/addons_config/nextcloud, executing"
bash /config/addons_config/nextcloud/*.sh
fi
