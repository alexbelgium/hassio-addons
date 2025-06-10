#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Where is the config
CONFIGSOURCE=$(bashio::config "PMM_CONFIG")

##################
# Create folders #
##################

PUID=$(bashio::config 'PUID')
PGID=$(bashio::config 'PGID')

if [ ! -d "$(dirname "${CONFIGSOURCE}")" ]; then
	echo "Creating $(dirname "${CONFIGSOURCE}")"
	mkdir -p "$(dirname "${CONFIGSOURCE}")"
fi

chown -R "$PUID":"$PGID" "$(dirname "${CONFIGSOURCE}")"

###################
# Set config.yaml #
###################

# Check if config file is there, or create one from template
if [ -f "$CONFIGSOURCE" ]; then
	bashio::log.info "Using config file found in $CONFIGSOURCE"
else
	cp /templates/config.yml "$(dirname "${CONFIGSOURCE}")"
	bashio::log.warning "No config file, creating one from template. Please correct the config.yml file before restarting the addon !"
fi
