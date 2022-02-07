#!/usr/bin/with-contenv bashio

##################
# Create folders #
##################

PUID=$(bashio::config 'PUID')
GUID=$(bashio::config 'GUID')

if [ ! -d /config/addons_config/plex-meta-manager ]; then
  echo "Creating /config/addons_config/plex-meta-manager"
  mkdir -p /config/addons_config/plex-meta-manager
fi

chown -R "$PUID":"$GUID" /config/addons_config/plex-meta-manager

###################
# Set config.yaml #
###################

# Where is the config
CONFIGSOURCE=$(bashio::config "PMM_CONFIG")
CONFIGSOURCE=$(dirname "$CONFIGSOURCE")

# Check if config file is there, or create one from template
if [ -f "$CONFIGSOURCE"/config.yml ]; then
    bashio::log.info "Using config file found in $CONFIGSOURCE"
else
    cp /templates/config.yml "$(dirname "${CONFIGSOURCE}")"
    bashio::log.warning "No config file, creating one from template. Please correct the config.yml file before restarting the addon !"
    sleep 10
    bashio::addon.stop
fi
