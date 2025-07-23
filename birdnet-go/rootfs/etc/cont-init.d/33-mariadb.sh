#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Gives mariadb information

if bashio::services.available 'mysql'; then
    bashio::log.green "---"
    bashio::log.yellow "MariaDB addon is active on your system! If you want to use it instead of sqlite, here are the informations to encode :"
    bashio::log.blue "Database user : $(bashio::services "mysql" "username")"
    bashio::log.blue "Database password : $(bashio::services "mysql" "password")"
    bashio::log.blue "Database name : birdnet"
    bashio::log.blue "Host-name : $(bashio::services "mysql" "host")"
    bashio::log.blue "Port : $(bashio::services "mysql" "port")"
    bashio::log.green "---"
fi
