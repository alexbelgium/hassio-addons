#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

##################
# INITIALIZATION #
##################

# Where is the config
CONFIGSOURCE=$(bashio::config "CONFIG_LOCATION")
# Check CONFIGSOURCE ends with config.yaml
if [ "$(basename "$CONFIGSOURCE")" != "config.yaml" ]; then
    bashio::log.error "Watchout: your CONFIG_LOCATION should end by config.yaml, and instead it is $(basename "$CONFIGSOURCE")"
fi
DATABASESOURCE="$(dirname "${CONFIGSOURCE}")/cache.db"

# Make sure folder exist
mkdir -p "$(dirname "${CONFIGSOURCE}")"
mkdir -p "$(dirname "${DATABASESOURCE}")"
chmod 777 -R "$(dirname "${CONFIGSOURCE}")"
chmod 777 -R "$(dirname "${DATABASESOURCE}")"

# Check absence of config file
if [ -f /data/config.yaml ] && [ ! -L /data/config.yaml ]; then
    bashio::log.warning "A current config was found in /data, it is backuped to ${CONFIGSOURCE}.bak"
    mv /data/config.yaml "$CONFIGSOURCE".bak
fi

#########################################################
# MIGRATION FROM ENEDISGATEWAY2MQTT TO MYELECTRICALDATA #
#########################################################

if [ -f /config/addons_config/enedisgateway2mqtt_dev/config.yaml ]; then
    mv /config/addons_config/enedisgateway2mqtt_dev/* "$(dirname "${CONFIGSOURCE}")"/
    rm -r /config/addons_config/enedisgateway2mqtt_dev
fi

# If migration was performed, save file in config folder
if [ -f /data/enedisgateway.db.migrate ]; then
    bashio::log.warning "Migration performed, enedisgateway.db.migrate copied in $(dirname "${CONFIGSOURCE}")"
    mv /data/enedisgateway.db.migrate "$(dirname "${CONFIGSOURCE}")"
fi

# If migration was performed, save file in config folder
if [ -f /data/cache.db ] && [ ! -f "$DATABASESOURCE" ]; then
    mv /data/cache.db "$(dirname "${CONFIGSOURCE}")"
fi

# If migration was not performed, enable migration
if [ -f "$(dirname "${CONFIGSOURCE}")"/enedisgateway.db ]; then
    mv "$(dirname "${CONFIGSOURCE}")"/enedisgateway.db /data
fi

############
# DATABASE #
############

# Check if database is here or create symlink
if [ -f "$DATABASESOURCE" ]; then
    # Create symlink if not existing yet
    ln -sf "${DATABASESOURCE}" /data && echo "creating symlink"
    bashio::log.info "Using database file found in $(dirname "${CONFIGSOURCE}")"
else
    # Create symlink for addon to create database
    mkdir -p "$(dirname "$DATABASESOURCE")"
    touch "${DATABASESOURCE}"
    ln -sf "$DATABASESOURCE" /data
    rm "$DATABASESOURCE"
fi

##########
# CONFIG #
##########

# Check if config file is there, or create one from template
if [ -f "$CONFIGSOURCE" ]; then
    # Create symlink if not existing yet
    # shellcheck disable=SC2015
    [ -f /data/config.yaml ] && rm /data/config.yaml || true
    ln -sf "$CONFIGSOURCE" /data || true
    bashio::log.info "Using config file found in $CONFIGSOURCE"

    # Check if yaml is valid
    EXIT_CODE=0
    yamllint -d relaxed "$CONFIGSOURCE" &> ERROR || EXIT_CODE=$?
    if [ "$EXIT_CODE" = 0 ]; then
        echo "Config file is a valid yaml"
    else
        cat ERROR
        bashio::log.fatal "Config file has an invalid yaml format. Please check the file in $CONFIGSOURCE. Errors list above. You can check yaml validity with the online tool yamllint.com"
    fi
else
    # Create symlink for addon to create config
    cp /templates/config.yaml "$(dirname "${CONFIGSOURCE}")"/
    ln -sf "$CONFIGSOURCE" /data
    rm "$CONFIGSOURCE"
    # Need to restart
    bashio::log.fatal "Config file not found. The addon will create a new one, then stop. Please customize the file in $CONFIGSOURCE before restarting."
fi

##############
# Launch App #
##############
echo " "
nginx &
bashio::log.info "Starting nginx"
echo " "
bashio::log.info "Starting the app"
echo " "

python -u /app/main.py || bashio::log.fatal "The app has crashed. Are you sure you entered the correct config options?"
