#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2155

####################
# Define defaults #
####################

DEFAULT_PAPERLESS_DATA_DIR="/config/addons_config/paperless_ng"
DEFAULT_PAPERLESS_MEDIA_ROOT="/config/addons_config/paperless_ng/media"
DEFAULT_PAPERLESS_CONSUMPTION_DIR="/config/addons_config/paperless_ng/consume"

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

if bashio::config.has_value "PAPERLESS_DATA_DIR"; then export PAPERLESS_URL=$(bashio::config "PAPERLESS_DATA_DIR"); else export $DEFAULT_PAPERLESS_DATA_DIR ; fi
if bashio::config.has_value "PAPERLESS_MEDIA_ROOT"; then export PAPERLESS_URL=$(bashio::config "PAPERLESS_MEDIA_ROOT"); else export $DEFAULT_PAPERLESS_MEDIA_ROOT ; fi
if bashio::config.has_value "PAPERLESS_CONSUMPTION_DIR"; then export PAPERLESS_URL=$(bashio::config "PAPERLESS_CONSUMPTION_DIR"); else export $DEFAULT_PAPERLESS_CONSUMPTION_DIR ; fi

export PAPERLESS_ADMIN_PASSWORD="admin"
export PAPERLESS_ADMIN_USER="admin"
export PAPERLESS_ALLOWED_HOSTS="*"

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

/./sbin/docker-entrypoint.sh /usr/local/bin/paperless_cmd.sh
