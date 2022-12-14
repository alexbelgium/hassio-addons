#!/usr/bin/env bashio
# shellcheck shell=bash

##################
# INITIALIZATION #
##################

# Where is the config
CONFIGSOURCE=$(bashio::config "CONFIG_LOCATION")
DATABASESOURCE="$(dirname "${CONFIGSOURCE}")/cache.db"

# Make sure folder exist
mkdir -p "$(dirname "${CONFIGSOURCE}")"
mkdir -p "$(dirname "${DATABASESOURCE}")"

# Check absence of config file
if [ -f /data/config.yaml ] && [ ! -L /data/config.yaml ]; then
    bashio::log.warning "A current config was found in /data, it is backuped to ${CONFIGSOURCE}.bak"
    mv /data/config.yaml "$CONFIGSOURCE".bak
fi

############
# DATABASE #
############

# If migration was performed, save file in config folder
if [ -f /data/enedisgateway.db.migrate ]; then
    bashio::log.warning "Migration performed, enedisgateway.db.migrate copied in $(dirname "${CONFIGSOURCE}")"
    mv /data/enedisgateway.db.migrate "$(dirname "${CONFIGSOURCE}")"
fi

# If migration was performed, save file in config folder
if [ -f /data/cache.db ] && [ ! -f "$DATABASESOURCE" ]; then
    if [ -f "$(dirname "${CONFIGSOURCE}")"/enedisgateway.db ]; then mv "$(dirname "${CONFIGSOURCE}")"/enedisgateway.db "$(dirname "${CONFIGSOURCE}")"/enedisgateway.db.bak2; fi
    mv /data/cache.db "$(dirname "${CONFIGSOURCE}")"
fi

# If migration was not performed, enable migration
if [ -f "$(dirname "${CONFIGSOURCE}")"/enedisgateway.db ]; then 
  mv "$(dirname "${CONFIGSOURCE}")"/enedisgateway.db /data
fi

# Check if database is here or create symlink
if [ -f "$DATABASESOURCE" ]; then
    # Create symlink if not existing yet
    ln -sf "${DATABASESOURCE}" /data && echo "creating symlink"
    bashio::log.info "Using database file found in $(dirname "${CONFIGSOURCE}")"
else
    # Create symlink for addon to create database
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
    [ ! -L /data/config.yaml ] && ln -sf "$CONFIGSOURCE" /data
    bashio::log.info "Using config file found in $CONFIGSOURCE"

    # Check if yaml is valid
    EXIT_CODE=0
    yamllint -d relaxed "$CONFIGSOURCE" &>ERROR || EXIT_CODE=$?
    if [ "$EXIT_CODE" = 0 ]; then
        echo "Config file is a valid yaml"
    else
        cat ERROR
        bashio::log.fatal "Config file has an invalid yaml format. Please check the file in $CONFIGSOURCE. Errors list above. You can check yaml validity with the online tool yamllint.com"
        bashio::exit.nok
    fi
else
    # Create symlink for addon to create config
    touch "${CONFIGSOURCE}"
    ln -sf "$CONFIGSOURCE" /data
    rm "$CONFIGSOURCE"
    # Need to restart
    bashio::log.fatal "Config file not found. The addon will create a new one, then stop. Please customize the file in $CONFIGSOURCE before restarting."
fi

##############
# Launch App #
##############
echo " "
bashio::log.info "Starting the app"
echo " "

# Test mode
TZ=$(bashio::config "TZ")
if [ "$TZ" = "test" ]; then
    echo "secret mode found, launching script in /config/test.sh"
    cd /config || exit
    chmod 777 test.sh
    ./test.sh
fi

python -u /app/main.py || bashio::log.fatal "The app has crashed. Are you sure you entered the correct config options?"
