#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Runs only after initialization done
# shellcheck disable=SC2128
if [ ! -f /app/www/public/occ ]; then cp /etc/cont-init.d/"$(basename "${BASH_SOURCE}")" /scripts/ && exit 0; fi

if bashio::services.available 'mysql'; then

    bashio::log.green "---"
    bashio::log.yellow "MariaDB addon was found! It can't be configured automatically due to the way Nextcloud works, but you can configure it manually when running the web UI for the first time using those values :"
    bashio::log.blue "Database user : $(bashio::services "mysql" "username")"
    bashio::log.blue "Database password : $(bashio::services "mysql" "password")"
    bashio::log.blue "Database name : nextcloud"
    bashio::log.blue "Host-name : $(bashio::services "mysql" "host"):$(bashio::services "mysql" "port")"
    bashio::log.green "---"

fi
