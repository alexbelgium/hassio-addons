#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

##############
# Initialize #
##############

HOME="/config/addons_config/epicgamesfree"
if [ ! -f "$HOME"/config.json ]; then
    # Copy default config.json
    cp /templates/config.json "$HOME"/config.json
    chmod 755 "$HOME"/config.json
    bashio::log.warning "A default config.json file was copied in $HOME. Please customize according to https://github.com/claabs/epicgames-freegames-node#json-configuration and restart the add-on"
    sleep 5
    bashio::exit.nok
else
    bashio::log.warning "The config.json file found in $HOME will be used. Please customize according to https://github.com/claabs/epicgames-freegames-node#json-configuration and restart the add-on"
fi

# Permissions
chmod -R 777 "$HOME"

##############
# Launch App #
##############

echo " "
bashio::log.info "Starting the app"
echo " "

cd "/usr/app/config" || true
