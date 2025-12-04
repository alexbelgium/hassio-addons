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

######################
# APPLY ADDON CONFIG #
######################

# Handle run_on_startup option
if bashio::config.has_value "run_on_startup"; then
    if bashio::config.true "run_on_startup"; then
        bashio::log.info "run_on_startup is enabled"
        jq '.runOnStartup = true' "$CONFIG_JSON" > "${CONFIG_JSON}.tmp" && mv "${CONFIG_JSON}.tmp" "$CONFIG_JSON"
    else
        bashio::log.info "run_on_startup is disabled"
        jq '.runOnStartup = false' "$CONFIG_JSON" > "${CONFIG_JSON}.tmp" && mv "${CONFIG_JSON}.tmp" "$CONFIG_JSON"
    fi
fi

# Handle disable_cron option
if bashio::config.true "disable_cron"; then
    bashio::log.info "Cron schedule is disabled - the addon will only run on startup"
    jq 'del(.cronSchedule)' "$CONFIG_JSON" > "${CONFIG_JSON}.tmp" && mv "${CONFIG_JSON}.tmp" "$CONFIG_JSON"
fi

##############
# Launch App #
##############

echo " "
bashio::log.info "Starting the app"
echo " "

cd "/usr/app/config" || true
