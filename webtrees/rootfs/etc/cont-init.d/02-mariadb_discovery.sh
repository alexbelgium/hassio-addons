#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

if bashio::services.available 'mysql'; then

    bashio::log.green "---"
    bashio::log.yellow "MariaDB addon was found! If you want to use it, you need to use those values when doing the initial startup wizard, or modify manually the config.ini.php file in /config/data (mapped to /addon_configs/xxx-webtrees/data when accessing using a third party tool)"
    bashio::log.blue "Database user : $(bashio::services "mysql" "username")"
    bashio::log.blue "Database password : $(bashio::services "mysql" "password")"
    bashio::log.blue "Database name : webtrees"
    bashio::log.blue "Host-name : $(bashio::services "mysql" "host")"
    bashio::log.blue "Port : $(bashio::services "mysql" "port")"
    bashio::log.green "---"

fi
