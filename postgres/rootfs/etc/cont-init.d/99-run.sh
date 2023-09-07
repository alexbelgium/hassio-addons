#!/usr/bin/env bashio
# shellcheck shell=bash

# Use new config file
CONFIG_HOME="$(bashio::config "CONFIG_LOCATION")"
CONFIG_HOME="$(dirname "$CONFIG_HOME")"
mkdir -p "$CONFIG_HOME"
if [ ! -f "$CONFIG_HOME"/postgresql.conf ]; then
    # Copy default config.env
    if [ -f /usr/local/share/postgresql/postgresql.conf.sample ]; then
        cp /usr/local/share/postgresql/postgresql.conf.sample "$CONFIG_HOME"/postgresql.conf
    elif [ -f /usr/share/postgresql/postgresql.conf.sample ]; then
        cp /usr/share/postgresql/postgresql.conf.sample "$CONFIG_HOME"/postgresql.conf
    else
        bashio::exit.nok "Config file not found, please ask maintainer"
    fi
    bashio::log.warning "A default config.env file was copied in $CONFIG_HOME. Please customize according to https://hub.docker.com/_/postgres and restart the add-on"
else
    bashio::log.warning "The config.env file found in $CONFIG_HOME will be used. Please customize according to https://hub.docker.com/_/postgres and restart the add-on"
fi

# Define home
# Creating config location
mkdir -p "$PGDATA"
chown -R postgres:postgres "$PGDATA"
chmod 1777 "$PGDATA"

# Permissions
chmod -R 777 "$CONFIG_HOME"

# Copy new file
cp "$CONFIG_HOME"/postgresql.conf /data/

##############
# Launch App #
##############

# Go to folder
cd /data || true

echo " "
bashio::log.info "Starting the app"
echo " "

# Add docker-entrypoint command
# shellcheck disable=SC2086
docker-entrypoint.sh postgres
