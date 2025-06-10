#!/usr/bin/env bashio
# shellcheck shell=bash
set -e
# hadolint ignore=SC2155

#################
# Define config #
#################

CONFIGSOURCE="/config/addons_config/zoneminder"
if [ ! -f "$CONFIGSOURCE"/zm.conf ]; then

    # Copy conf files
    cp /etc/zm/zm.conf "$CONFIGSOURCE"
fi

###################
# Define database #
###################

bashio::log.info "Defining database"
case "$(bashio::config "DB_CONNECTION")" in

        # Use MariaDB
    mariadb_addon)
        bashio::log.info "Using MariaDB addon. Requirements : running MariaDB addon. Detecting values..."
        if ! bashio::services.available 'mysql'; then
            bashio::log.fatal \
                "Local database access should be provided by the MariaDB addon"
            bashio::exit.nok \
                "Please ensure it is installed and started"
    fi

        # Use values
        DB_CONNECTION=mysql
        ZM_DB_HOST=$(bashio::services "mysql" "host")
        ZM_DB_PORT=$(bashio::services "mysql" "port")
        ZM_DB_NAME=firefly
        ZM_DB_USER=$(bashio::services "mysql" "username")
        ZM_DB_PASS=$(bashio::services "mysql" "password")
        export DB_CONNECTION
        export remoteDB=1
        export ZM_DB_HOST && bashio::log.blue "ZM_DB_HOST=$ZM_DB_HOST"
        export ZM_DB_PORT && bashio::log.blue "ZM_DB_PORT=$ZM_DB_PORT"
        export ZM_DB_NAME && bashio::log.blue "ZM_DB_NAME=$ZM_DB_NAME"
        export ZM_DB_USER && bashio::log.blue "ZM_DB_USER=$ZM_DB_USER"
        export ZM_DB_PASS && bashio::log.blue "ZM_DB_PASS=$ZM_DB_PASS"

        bashio::log.warning "Firefly-iii is using the Maria DB addon"
        bashio::log.warning "Please ensure this is included in your backups"
        bashio::log.warning "Uninstalling the MariaDB addon will remove any data"

        bashio::log.info "Creating database for Firefly-iii if required"
        mysql \
            -u "${ZM_DB_USER}" -p"${ZM_DB_PASS}" \
            -h "${ZM_DB_HOST}" -P "${ZM_DB_PORT}" \
            -e 'CREATE DATABASE IF NOT EXISTS `firefly` ;'
        ;;

        # Use remote
    external)
        bashio::log.info "Using remote database. Requirement : filling all addon options fields, and making sure the database already exists"
        for conditions in "ZM_DB_HOST" "ZM_DB_PORT" "ZM_DB_NAME" "ZM_DB_USER" "ZM_DB_PASS"; do
            if ! bashio::config.has_value "$conditions"; then
                bashio::exit.nok "Remote database has been specified but $conditions is not defined in addon options"
      fi
    done
        ;;

        # Use remote
    *)
        bashio::log.info "Using internal database"
        ;;

esac

##############
# LAUNCH APP #
##############

bashio::log.info "Please wait while the app is loading !"

./usr/local/bin/entrypoint.sh
