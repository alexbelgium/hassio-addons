#!/usr/bin/env bashio
# shellcheck shell=bash
set -e
set +u

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
        export PHOTOPRISM_DATABASE_DRIVER && \
            bashio::log.blue "PHOTOPRISM_DATABASE_DRIVER=$PHOTOPRISM_DATABASE_DRIVER"
        export PHOTOPRISM_DATABASE_SERVER && \
            bashio::log.blue "PHOTOPRISM_DATABASE_SERVER=$PHOTOPRISM_DATABASE_SERVER"
        export PHOTOPRISM_DATABASE_NAME && \
            bashio::log.blue "PHOTOPRISM_DATABASE_NAME=$PHOTOPRISM_DATABASE_NAME"
        export PHOTOPRISM_DATABASE_USER && \
            bashio::log.blue "PHOTOPRISM_DATABASE_USER=$PHOTOPRISM_DATABASE_USER"
        export PHOTOPRISM_DATABASE_PASSWORD && \
            bashio::log.blue "PHOTOPRISM_DATABASE_PASSWORD=$PHOTOPRISM_DATABASE_PASSWORD"

        {
            echo "export PHOTOPRISM_DATABASE_DRIVER=\"${PHOTOPRISM_DATABASE_DRIVER}\""
            echo "export PHOTOPRISM_DATABASE_SERVER=\"${PHOTOPRISM_DATABASE_SERVER}\""
            echo "export PHOTOPRISM_DATABASE_NAME=\"${PHOTOPRISM_DATABASE_NAME}\""
            echo "export PHOTOPRISM_DATABASE_USER=\"${PHOTOPRISM_DATABASE_USER}\""
            echo "export PHOTOPRISM_DATABASE_PASSWORD=\"${PHOTOPRISM_DATABASE_PASSWORD}\""
        } >> ~/.bashrc

        bashio::log.warning "Photoprism is using the Maria DB addon"
        bashio::log.warning "Please ensure this is included in your backups"
        bashio::log.warning "Uninstalling the MariaDB addon will remove any data"

        # Create database
        mysql --skip-ssl --host="$(bashio::services 'mysql' 'host')" --port="$(bashio::services 'mysql' 'port')" --user="$PHOTOPRISM_DATABASE_USER" --password="$PHOTOPRISM_DATABASE_PASSWORD" -e"CREATE DATABASE IF NOT EXISTS $PHOTOPRISM_DATABASE_NAME;"
        # Force character set
        mysql --skip-ssl --host="$(bashio::services 'mysql' 'host')" --port="$(bashio::services 'mysql' 'port')" --user="$PHOTOPRISM_DATABASE_USER" --password="$PHOTOPRISM_DATABASE_PASSWORD" -e"ALTER DATABASE $PHOTOPRISM_DATABASE_NAME CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;" || true
        ;;
esac

###########
# Ingress #
###########

if bashio::config.true "ingress_disabled"; then
    bashio::log.warning "Ingress is disabled. You'll need to connect using ip:port"
    sed -i "s|$(bashio::addon.ingress_entry)||g" /etc/nginx/servers/ssl.conf
    sed -i "s|location = /|location = /null|g" /etc/nginx/servers/ssl.conf
    # sed -i "7,10d" /etc/nginx/servers/ssl.conf
    # rm /etc/nginx/servers/ingress.conf
else
    PHOTOPRISM_SITE_URL="$(bashio::addon.ingress_entry)/"
    export PHOTOPRISM_SITE_URL
    echo "export PHOTOPRISM_SITE_URL=\"${PHOTOPRISM_SITE_URL}\"" >> ~/.bashrc
    bashio::log.warning "Ingress is enabled. To connect, you must add $PHOTOPRISM_SITE_URL to the end of your access point. Example : http://my-url:8123$PHOTOPRISM_SITE_URL"
fi

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

{
    echo "export PHOTOPRISM_UPLOAD_NSFW=\"${PHOTOPRISM_UPLOAD_NSFW}\""
    echo "export PHOTOPRISM_STORAGE_PATH=\"${PHOTOPRISM_STORAGE_PATH}\""
    echo "export PHOTOPRISM_ORIGINALS_PATH=\"${PHOTOPRISM_ORIGINALS_PATH}\""
    echo "export PHOTOPRISM_IMPORT_PATH=\"${PHOTOPRISM_IMPORT_PATH}\""
    echo "export PHOTOPRISM_BACKUP_PATH=\"${PHOTOPRISM_BACKUP_PATH}\""
} >> ~/.bashrc

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

# Define id
if bashio::config.has_value "PUID" && bashio::config.has_value "PGID"; then
    PUID="$(bashio::config "PUID")"
    PGID="$(bashio::config "PGID")"
    export PHOTOPRISM_UID="$PUID"
    export PHOTOPRISM_GID="$PGID"
    sed -i "1a PHOTOPRISM_UID=$PHOTOPRISM_UID" /scripts/entrypoint.sh
    sed -i "1a PHOTOPRISM_GID=$PHOTOPRISM_GID" /scripts/entrypoint.sh
    {
        echo "export PHOTOPRISM_UID=\"${PHOTOPRISM_UID}\""
        echo "export PHOTOPRISM_GID=\"${PHOTOPRISM_GID}\""
    } >> ~/.bashrc
fi

# Start messages
bashio::log.info "Please wait 1 or 2 minutes to allow the server to load"
bashio::log.info 'Default username : admin, default password: "please_change_password"'

# shellcheck disable=SC1091
. /scripts/entrypoint.sh photoprism start & bashio::log.info "Starting, please wait for next green text..."

bashio::net.wait_for 2341 localhost 900
bashio::log.info "App launched"

exec nginx
