#!/usr/bin/env bashio
# shellcheck shell=bash

cp /defaults/.env.example /.env

####################
# GLOBAL VARIABLES #
####################
sed -i "s|NOSWAG=0|NOSWAG=1|g" .env
sed -i "s|USE_HTTPS=1|USE_HTTPS=0|g" .env
sed -i "s|PUID=1000|PUID=$(bashio::config 'PUID')|g" .env
sed -i "s|PGID=1000|PGID=$(bashio::config 'PGID')|g" .env
sed -i "s|TZ=Europe/Zurich|TZ=$(bashio::config 'TZ')|g" .env
sed -i "s|URL=your.domain|URL=$(bashio::config 'SEAFILE_SERVER_HOSTNAME')|g" .env
sed -i "s|SEAFILE_ADMIN_EMAIL=you@your.email|SEAFILE_ADMIN_EMAIL=$(bashio::config 'SEAFILE_ADMIN_EMAIL')|g" .env
sed -i "s|SEAFILE_CONF_DIR=./seafile/conf|SEAFILE_CONF_DIR=$(bashio::config 'data_location')/conf|g" .env
sed -i "s|SEAFILE_LOGS_DIR=./seafile/logs|SEAFILE_LOGS_DIR=$(bashio::config 'data_location')/logs|g" .env
sed -i "s|SEAFILE_DATA_DIR=./seafile/seafile-data|SEAFILE_DATA_DIR=$(bashio::config 'data_location')/seafile-data|g" .env
sed -i "s|SEAFILE_SEAHUB_DIR=./seafile/seahub-data|SEAFILE_SEAHUB_DIR=$(bashio::config 'data_location'/seahub-data)|g" .env
sed -i "s|SEAFILE_SQLITE_DIR=./seafile/sqlite|SSEAFILE_SQLITE_DIR=$(bashio::config 'data_location'/sqlite)|g" .env
sed -i "s|DATABASE_DIR=./db|DATABASE_DIR=$(bashio::config 'data_location'/db)|g" .env

###################
# Define database #
###################
bashio::log.info "Defining database"
case $(bashio::config 'database') in
    
    # Use sqlite
    sqlite)
        sed -i "s|SQLITE=0|SQLITE=1|g" .env
    ;;
    
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
        sed -i "s|MYSQL_HOST=db|MYSQL_HOST=$(bashio::services "mysql" "host")|g" .env
        sed -i "s|MYSQL_USER_PASSWD=secret|MYSQL_USER_PASSWD=$(bashio::services "mysql" "username")|g" .env
        sed -i "s|MYSQL_ROOT_PASSWD=secret|MYSQL_USER_PASSWD=$(bashio::services "mysql" "password")|g" .env
        
        bashio::log.warning "This addon is using the Maria DB addon"
        bashio::log.warning "Please ensure this is included in your backups"
        bashio::log.warning "Uninstalling the MariaDB addon will remove any data"
    ;;
esac

##############
# LAUNCH APP #
##############

bashio::log.info "Starting app"
#/sbin/my_init -- /scripts/enterpoint.sh
/./docker_entrypoint.sh
