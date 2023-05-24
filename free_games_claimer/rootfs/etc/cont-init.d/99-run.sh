#!/usr/bin/env bashio
# shellcheck shell=bash

##############
# Initialize #
##############

# Delete file if existing
if [ -f /data/data/config.env ]; then
    rm /data/data/config.env
fi

# Use new config file
HOME="$(bashio::config "CONFIG_LOCATION")"
HOME="$(dirname "$HOME")"
if [ ! -f "$HOME"/config.env ]; then
    # Copy default config.env
    cp /templates/config.env "$HOME"/config.env
    chmod 777 "$HOME"/config.env
    bashio::log.warning "A default config.env file was copied in $HOME. Please customize according to https://github.com/vogler/free-games-claimer/tree/main#configuration--options and restart the add-on"
    sleep 5
    bashio::exit.nok
else
    bashio::log.warning "The config.env file found in $HOME will be used. Please customize according to https://github.com/vogler/free-games-claimer/tree/main#configuration--options and restart the add-on"
fi
cp "$HOME"/config.env /data/data/

# Permissions
chmod -R 777 "$HOME"

##############
# Launch App #
##############

cd /data || true

CMD_ARGUMENTS="$(bashio::config "CMD_ARGUMENTS")"

echo " "
bashio::log.info "Starting the app with arguments $CMD_ARGUMENTS"
echo " "

# shellcheck disable=SC2086
$CMD_ARGUMENTS || {node epic-games; node prime-gaming; node gog;}
