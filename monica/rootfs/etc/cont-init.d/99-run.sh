#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Gives mariadb information

###################
# Define database #
###################

bashio::log.info "Defining database"

DB_DATABASE="$(bashio::config 'DB_DATABASE')"
DB_HOST="$(bashio::config 'DB_HOST')"
DB_PASSWORD="$(bashio::config 'DB_PASSWORD')"
DB_PORT="$(bashio::config 'DB_PORT')"
DB_USERNAME="$(bashio::config 'DB_USERNAME')"

# Check if at least one variable is not empty
if [ -n "$DB_DATABASE" ] || [ -n "$DB_HOST" ] || [ -n "$DB_PASSWORD" ] || [ -n "$DB_PORT" ] || [ -n "$DB_USERNAME" ]; then
    # Alert if mariadb is available
    if bashio::services.available 'mysql'; then
        bashio::log.warning "The MariaDB addon is available, but you have selected to use your own database by manually configuring the addon options"
    fi
    # Verify all variables are not empty
    if [ -z "$DB_DATABASE" ] || [ -z "$DB_HOST" ] || [ -z "$DB_PASSWORD" ] || [ -z "$DB_PORT" ] || [ -z "$DB_USERNAME" ]; then
        bashio::log.fatal "You have selected to not use the automatic Mariadb detection by manually configuring the addon options, but not all. Ensure all are set: DB_DATABASE, DB_HOST, DB_PASSWORD, DB_PORT, DB_USERNAME."
        exit 1
    fi
else
    # User Mariadb
    bashio::log.info "Using MariaDB addon. Requirements : running MariaDB addon. Discovering values..."
    if ! bashio::services.available 'mysql'; then
        bashio::log.fatal \
        "Local database access should be provided by the MariaDB addon"
        bashio::exit.nok \
        "Please ensure it is installed and started"
    fi

    # Use values
    export DB_HOST=$(bashio::services "mysql" "host") && bashio::log.blue "DB_HOST=$DB_HOST" && sed "1a export DB_HOST=$DB_HOST" /usr/local/bin/entrypoint.sh
    export DB_PORT=$(bashio::services "mysql" "port") && bashio::log.blue "DB_PORT=$DB_PORT" && sed "1a export DB_PORT=$DB_PORT" /usr/local/bin/entrypoint.sh
    export DB_DATABASE=monica && bashio::log.blue "DB_DATABASE=$DB_DATABASE" && sed "1a export DB_DATABASE=$DB_DATABASE" /usr/local/bin/entrypoint.sh
    export DB_USERNAME=$(bashio::services "mysql" "username") && bashio::log.blue "DB_USERNAME=$DB_USERNAME" && sed "1a export DB_USERNAME=$DB_USERNAME" /usr/local/bin/entrypoint.sh
    export DB_PASSWORD=$(bashio::services "mysql" "password") && bashio::log.blue "DB_PASSWORD=$DB_PASSWORD" && sed "1a export DB_PASSWORD=$DB_PASSWORD" /usr/local/bin/entrypoint.sh

    bashio::log.warning "Monica is using the Maria DB addon"
    bashio::log.warning "Please ensure this is included in your backups"
    bashio::log.warning "Uninstalling the MariaDB addon will remove any data"

fi

###########
# APP_KEY #
###########

if [ ${#APP_KEY:=$(bashio::config "APP_KEY")} -ne 32 ]; then
    APP_KEY="$(echo -n 'base64:'; openssl rand -base64 32)"
    bashio::addon.option "APP_KEY" "${APP_KEY}"
    bashio::log.warning "The APP_KEY set was invalid, generated a random one: ${APP_KEY}. Restarting to take it into account"
    echo "${APP_KEY}" >> /config/APP_KEY
    bashio::addon.restart
fi
export APP_KEY="$(bashio::config "APP_KEY")"

bashio::log.info "Starting Monica"

/./usr/local/bin/entrypoint.sh
