#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

##############
# Initialize #
##############

HOME="/config/addons_config/epicgamesfree"
CONFIG_JSON="$HOME/config.json"
LEGACY_YAML="$HOME/config.yaml"

if [ ! -f "$CONFIG_JSON" ]; then
    if [ -f "$LEGACY_YAML" ]; then
        bashio::log.warning "A legacy config.yaml was found. A default config.json will be created. Please migrate your settings to the new file format and restart the add-on"
    fi

    # Copy default config.json
    cp /templates/config.json "$CONFIG_JSON"
    chmod 755 "$CONFIG_JSON"
    bashio::log.warning "A default config.json file was copied in $HOME. Please customize according to https://github.com/claabs/epicgames-freegames-node#configuration and restart the add-on"
    sleep 5
    bashio::exit.nok
else
    bashio::log.warning "The config.json file found in $HOME will be used. Please customize according to https://github.com/claabs/epicgames-freegames-node#configuration and restart the add-on"
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
