#!/usr/bin/env bashio
# shellcheck shell=bash

##############
# Initialize #
##############

# Use new config file
CONFIG_HOME="$(bashio::config "CONFIG_LOCATION")"
CONFIG_HOME="$(dirname "$CONFIG_HOME")"
if [ ! -f "$CONFIG_HOME"/config.env ]; then
    # Copy default config.env
    cp /templates/config.env "$CONFIG_HOME"/config.env
    chmod 777 "$CONFIG_HOME"/config.env
    bashio::log.warning "A default config.env file was copied in $CONFIG_HOME. Please customize according to https://github.com/vogler/free-games-claimer/tree/main#configuration--options and restart the add-on"
else
    bashio::log.warning "The config.env file found in $CONFIG_HOME will be used. Please customize according to https://github.com/vogler/free-games-claimer/tree/main#configuration--options and restart the add-on"
fi

# Copy new file
mkdir -p /data/data
\cp "$CONFIG_HOME"/config.env /data/data/

# Permissions
chmod -R 777 "$CONFIG_HOME"

# Export variables
set -a
cp /./"$CONFIG_HOME"/config.env /config.env
# Remove previous instance
sed -i "s|export ||g" /config.env
# Add export for non empty lines
sed -i '/\S/s/^/export /' /config.env
# Delete lines starting with #
sed -i '/export #/d' /config.env
# Get variables
# Shellcheck disable=SC1091
source /config.env
rm /config.env
set +a

##############
# Launch App #
##############

# Go to folder
cd /data || true

# Fetch commands
CMD_ARGUMENTS="$(bashio::config "CMD_ARGUMENTS")"

echo " "
bashio::log.info "Starting the app with arguments $CMD_ARGUMENTS"
echo " "

# Add docker-entrypoint command
# shellcheck disable=SC2086
docker-entrypoint.sh $CMD_ARGUMENTS || true

bashio::log.info "All actions concluded, addon will stop"
