#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

bashio::log.green "---"
if [ ! -f "%%data_location%%/config.ini.php" ]; then
    bashio::log.info "First boot : open the UI at $BASE_URL to access the start-up wizard"
    if bashio::services.available 'mysql'; then
        bashio::log.info "MariaDB is available, if you want to use it please fill the values below"
        bashio::log.blue "Host-name : $(bashio::services "mysql" "host")"
        bashio::log.blue "Port : $(bashio::services "mysql" "port")"
        bashio::log.blue "Database user : $(bashio::services "mysql" "username")"
        bashio::log.blue "Database password : $(bashio::services "mysql" "password")"
        bashio::log.blue "Database name : webtrees"
        bashio::log.blue "Database prefix : wt_"
        bashio::log.green "---"
    else
        bashio::log.info "As you don't have the MariaDB addon running, you should likely select sqlite as database, when the name webtrees"
    fi
else
    bashio::log.info "Webtrees started. You can access your webui at : %%baseurl%%"
fi
