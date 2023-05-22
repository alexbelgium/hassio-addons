#!/usr/bin/env bashio
# shellcheck shell=bash

##############
# Initialize #
##############

HOME="$(bashio::config "CONFIG_LOCATION")"
HOME="$(dirname "$HOME")"
if [ ! -f "$HOME"/config.yaml ]; then
    # Copy default config.yaml
    cp /templates/config.yaml "$HOME"/config.yaml
    chmod 777 "$HOME"/config.yaml
    bashio::log.warning "A default config.yaml file was copied in $HOME. Please customize according to https://github.com/vogler/free-games-claimer/tree/main#configuration--options and restart the add-on"
    sleep 5
    bashio::exit.nok
else
    bashio::log.warning "The config.yaml file found in $HOME will be used. Please customize according to https://github.com/vogler/free-games-claimer/tree/main#configuration--options and restart the add-on"
fi

# Permissions
chmod -R 777 "$HOME"

##############
# Launch App #
##############

cd /data || true

echo " "
bashio::log.info "Starting the app"
echo " "
