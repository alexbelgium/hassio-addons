#!/usr/bin/env bashio
# shellcheck shell=bash

############
# Base url #
############

#PHOTOPRISM_SITE_URL="$(bashio::config 'PHOTOPRISM_SITE_URL')$(bashio::addon.ingress_entry)"
#bashio::log.blue "Site url : $PHOTOPRISM_SITE_URL"
#export PHOTOPRISM_SITE_URL

###################
# Define database #
###################

bashio::log.info "Defining database"

case $(bashio::config 'DB_TYPE') in

        # Use sqlite
    sqlite)
        bashio::log.info "Using a local sqlite database"
        ;;

    mariadb_addon)
        bashio::log.info "Using MariaDB addon. Requirements : running MariaDB addon. Discovering values..."
        if ! bashio::services.available 'mysql'; then
            bashio::log.fatal \
                "Local database access should be provided by the MariaDB addon"
            bashio::exit.nok \
                "Please ensure it is installed and started"
        fi

        # Install mysqlclient
        pip install pymysql &>/dev/null || true

        # Use values
        PHOTOPRISM_DATABASE_DRIVER="mysql"
        PHOTOPRISM_DATABASE_SERVER="$(bashio::services 'mysql' 'host'):$(bashio::services 'mysql' 'port')"
        PHOTOPRISM_DATABASE_NAME="photoprism"
        PHOTOPRISM_DATABASE_USER="$(bashio::services 'mysql' 'username')"
        PHOTOPRISM_DATABASE_PASSWORD="$(bashio::services 'mysql' 'password')"
        export PHOTOPRISM_DATABASE_DRIVER && bashio::log.blue "PHOTOPRISM_DATABASE_DRIVER=$PHOTOPRISM_DATABASE_DRIVER"
        export PHOTOPRISM_DATABASE_SERVER && bashio::log.blue "PHOTOPRISM_DATABASE_SERVER=$PHOTOPRISM_DATABASE_SERVER"
        export PHOTOPRISM_DATABASE_NAME && bashio::log.blue "PHOTOPRISM_DATABASE_NAME=$PHOTOPRISM_DATABASE_NAME"
        export PHOTOPRISM_DATABASE_USER && bashio::log.blue "PHOTOPRISM_DATABASE_USER=$PHOTOPRISM_DATABASE_USER"
        export PHOTOPRISM_DATABASE_PASSWORD && bashio::log.blue "PHOTOPRISM_DATABASE_PASSWORD=$PHOTOPRISM_DATABASE_PASSWORD"

        bashio::log.warning "Webtrees is using the Maria DB addon"
        bashio::log.warning "Please ensure this is included in your backups"
        bashio::log.warning "Uninstalling the MariaDB addon will remove any data"

        # Create database
        mysql --host="$(bashio::services 'mysql' 'host')" --port="$(bashio::services 'mysql' 'port')" --user="$PHOTOPRISM_DATABASE_USER" --password="$PHOTOPRISM_DATABASE_PASSWORD" -e"CREATE DATABASE IF NOT EXISTS $PHOTOPRISM_DATABASE_NAME;"
        # Force character set
        mysql --host="$(bashio::services 'mysql' 'host')" --port="$(bashio::services 'mysql' 'port')" --user="$PHOTOPRISM_DATABASE_USER" --password="$PHOTOPRISM_DATABASE_PASSWORD" -e"ALTER DATABASE $PHOTOPRISM_DATABASE_NAME CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;" || true
        ;;
esac

##############
# LAUNCH APP #
##############

# Configure app
PHOTOPRISM_UPLOAD_NSFW=$(bashio::config 'UPLOAD_NSFW')
PHOTOPRISM_STORAGE_PATH=$(bashio::config 'STORAGE_PATH')
PHOTOPRISM_ORIGINALS_PATH=$(bashio::config 'ORIGINALS_PATH')
PHOTOPRISM_IMPORT_PATH=$(bashio::config 'IMPORT_PATH')
PHOTOPRISM_BACKUP_PATH=$(bashio::config 'BACKUP_PATH')
export PHOTOPRISM_UPLOAD_NSFW
export PHOTOPRISM_STORAGE_PATH
export PHOTOPRISM_ORIGINALS_PATH
export PHOTOPRISM_IMPORT_PATH
export PHOTOPRISM_BACKUP_PATH

# Test configs
for variabletest in $PHOTOPRISM_STORAGE_PATH $PHOTOPRISM_ORIGINALS_PATH $PHOTOPRISM_IMPORT_PATH $PHOTOPRISM_BACKUP_PATH; do
    # Check if path exists
    if bashio::fs.directory_exists "$variabletest"; then
        true
    else
        bashio::log.info "Path $variabletest doesn't exist. Creating it now..."
        mkdir -p "$variabletest" || bashio::log.fatal "Can't create $variabletest path"
    fi
    # Check if path writable
    # shellcheck disable=SC2015
    touch "$variabletest"/aze && rm "$variabletest"/aze || bashio::log.fatal "$variabletest path is not writable"
done

# Start messages
bashio::log.info "Please wait 1 or 2 minutes to allow the server to load"
bashio::log.info 'Default username : admin, default password: "please_change_password"'

cd /
./scripts/entrypoint.sh photoprism start & bashio::log.info "Starting, please wait for next green text..."

bashio::net.wait_for 2341 localhost 900
bashio::log.info "App launched"

exec nginx
