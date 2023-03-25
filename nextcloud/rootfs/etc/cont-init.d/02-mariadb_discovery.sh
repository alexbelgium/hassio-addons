#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

if bashio::services.available 'mysql'; then

    bashio::log.green "---"
    bashio::log.yellow "MariaDB addon was found! It can't be configured automatically due to the way Nextcloud works, but you can configure it manually when running the web UI for the first time using those values :"
    bashio::log.blue "Database user : $(bashio::services "mysql" "username")"    bashio::log.blue "Database user : $(bashio::services "mysql" "username")"
    bashio::log.blue "Database password : $(bashio::services "mysql" "password")"
    bashio::log.blue "Database name : nextcloud"
    bashio::log.blue "Host-name : $(bashio::services "mysql" "host"):$(bashio::services "mysql" "port")"
    bashio::log.green "---"

    # Clean if needed
    for var in dbtype dbname dbuser dbhost; do
        sed -i "/$var/d" /defaults/config.php
    done
fi
