#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2155

####################
# Define variables #
####################

bashio::log.info "Defining variables"

if bashio::config.has_value "PUID"; then export USERMAP_UID=$(bashio::config "PUID"); fi
if bashio::config.has_value "PGID"; then export USERMAP_GID=$(bashio::config "PGID"); fi
if bashio::config.has_value "TZ"; then export PAPERLESS_TIME_ZONE=$(bashio::config "TZ"); fi
if bashio::config.has_value "PAPERLESS_URL"; then export PAPERLESS_URL=$(bashio::config "PAPERLESS_URL"); fi
if bashio::config.has_value "OCRLANG"; then
    PAPERLESS_OCR_LANGUAGES="$(bashio::config "OCRLANG")"
    export PAPERLESS_OCR_LANGUAGES=${PAPERLESS_OCR_LANGUAGES,,}
fi
if bashio::config.has_value "PAPERLESS_OCR_MODE"; then export PAPERLESS_OCR_MODE=$(bashio::config "PAPERLESS_OCR_MODE"); fi

export PAPERLESS_ADMIN_PASSWORD="admin"
export PAPERLESS_ADMIN_USER="admin"
export PAPERLESS_ALLOWED_HOSTS="*"

export PAPERLESS_DATA_DIR="/config/data"
export PAPERLESS_MEDIA_ROOT="/config/media"
export PAPERLESS_CONSUMPTION_DIR="/config/consume"
export PAPERLESS_EXPORT_DIR="/config/export"
chown -R paperless:paperless /config

for variable in "PAPERLESS_DATA_DIR" "PAPERLESS_MEDIA_ROOT" "PAPERLESS_CONSUMPTION_DIR" "PAPERLESS_EXPORT_DIR"; do
    # Import new variable if set in options
    if bashio::config.has_value "$variable"; then export "$variable"=$(bashio::config "$variable"); fi
    # Create folder and permissions if needed
    mkdir -p "$variable"
    chmod -R 755 "$variable"
    chown -R paperless:paperless "$variable"
done

###################
# Define database #
###################

bashio::log.info "Defining database"

case $(bashio::config 'database') in

        # Use mariadb
    mariadb_addon)
        bashio::log.info "Using MariaDB addon. Requirements : running MariaDB addon. Discovering values..."
        if ! bashio::services.available 'mysql'; then
            bashio::log.fatal \
                "Local database access should be provided by the MariaDB addon"
            bashio::exit.nok \
                "Please ensure it is installed and started"
        fi

        # Use values
        export PAPERLESS_DBENGINE=mariadb
        export PAPERLESS_DBHOST="$(bashio::services 'mysql' 'host')"
        export PAPERLESS_DBPORT="$(bashio::services 'mysql' 'port')"
        export PAPERLESS_DBNAME=paperless
        export PAPERLESS_DBUSER="$(bashio::services "mysql" "username")"
        export PAPERLESS_DBPASS="$(bashio::services "mysql" "password")"

        # Create database
        mysql --host="$PAPERLESS_DBHOST" --port="$PAPERLESS_DBPORT" --user="$PAPERLESS_DBUSER" --password="$PAPERLESS_DBPASS" -e"CREATE DATABASE IF NOT EXISTS $PAPERLESS_DBNAME;"

        # Informations
        bashio::log.warning "This addon is using the Maria DB addon"
        bashio::log.warning "Please ensure this is included in your backups"
        bashio::log.warning "Uninstalling the MariaDB addon will remove any data"
        ;;


        # Use sqlite
    *)
        bashio::log.info "Using sqlite as database driver"
        ;;
esac

set +u
# For all relevant variables
for variable in USERMAP_UID USERMAP_GID PAPERLESS_TIME_ZONE PAPERLESS_URL PAPERLESS_OCR_LANGUAGES PAPERLESS_OCR_MODE PAPERLESS_ADMIN_PASSWORD PAPERLESS_ADMIN_USER PAPERLESS_ALLOWED_HOSTS PAPERLESS_DATA_DIR PAPERLESS_MEDIA_ROOT PAPERLESS_CONSUMPTION_DIR PAPERLESS_DBENGINE PAPERLESS_DBHOST PAPERLESS_DBPORT PAPERLESS_DBNAME PAPERLESS_DBUSER PAPERLESS_DBPASS; do

    # Variable content
    variablecontent="$(eval echo "\$$variable")"

    # Skip if variable content empty
    if [ ${#variablecontent} -le 2 ]; then
        continue
    fi

    # Export
    export "$variable=$variablecontent"
    # Add to bashrc
    eval echo "$variable=\"$variablecontent\"" >> ~/.bashrc
    # set .env
    echo "$variable=\"$variablecontent\"" >> /.env || true
    # set /etc/environmemt
    mkdir -p /etc
    echo "$variable=\"$variablecontent\"" >> /etc/environmemt
    # For s6
    if [ -d /var/run/s6/container_environment ]; then printf "%s" "${variablecontent}" > /var/run/s6/container_environment/"${variable}"; fi
done

#################
# Staring redis #
#################
exec redis-server & bashio::log.info "Starting redis"

#################
# Staring nginx #
#################
exec nginx & bashio::log.info "Starting nginx"

###############
# Staring app #
###############
bashio::log.info "Initial username and password are admin. Please change in the administration panel of the webUI after login."
