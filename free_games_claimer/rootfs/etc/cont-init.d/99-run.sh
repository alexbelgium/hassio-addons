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
\cp "$CONFIG_HOME"/config.env /data/

# Permissions
chmod -R 777 "$CONFIG_HOME"

# Export variables
set -a
/./"$CONFIG_HOME"/config.env
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
# docker-entrypoint.sh $CMD_ARGUMENTS
