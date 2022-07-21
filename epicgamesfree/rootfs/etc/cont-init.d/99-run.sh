#!/usr/bin/env bashio
# shellcheck shell=bash

##############
# Initialize #
##############

# Copy default config.json
HOME="/config/addons_config/epicgamesfree"
if [ ! -f "$HOME"/config.json ]; then
    cp /templates/config.json "$HOME"/config.json
    chmod 777 "$HOME"/config.json
    bashio::log.warning "A default config.json file was copied in $HOME. Please customize according to https://github.com/claabs/epicgames-freegames-node#json-configuration before restarting the addon"
    bashio::exit.nok
fi

# Make symlink

if [ -f /usr/app/config/config.json ]; then rm /usr/app/config/config.json; fi
ln -s "$HOME"/config.json /usr/app/config/config.json

##############
# Launch App #
##############

echo " "
bashio::log.info "Starting the app"
echo " "

/./usr/local/bin/docker-entrypoint.sh
