#!/usr/bin/env bashio
# shellcheck shell=bash

#################
# DATA_LOCATION #
#################

bashio::log.info "Setting data location"
DATA_LOCATION=$(bashio::config 'data_location')

echo "Check $DATA_LOCATION folder exists"
mkdir -p "$DATA_LOCATION"

echo "Setting permissions"
chown -R "$(bashio::config 'PUID'):$(bashio::config 'PGID')" "$DATA_LOCATION"
chmod -R 755 "$DATA_LOCATION"

echo "Creating symlink"
ln -sf "$DATA_LOCATION" /shared

sed -i "1a export SEAFILE_CONF_DIR=$DATA_LOCATION/conf" /home/seafile/*.sh
sed -i "1a export SEAFILE_LOGS_DIR=$DATA_LOCATION/logs" /home/seafile/*.sh
sed -i "1a export SEAFILE_DATA_DIR=$DATA_LOCATION/seafile-data" /home/seafile/*.sh
sed -i "1a export SEAFILE_SEAHUB_DIR=$DATA_LOCATION/seahub-data" /home/seafile/*.sh
sed -i "1a export SEAFILE_SQLITE_DIR=$DATA_LOCATION/sqlite" /home/seafile/*.sh
sed -i "1a export DATABASE_DIR=$DATA_LOCATION/db" /home/seafile/*.sh

###################
# Define database #
###################

bashio::log.info "Defining database"

case $(bashio::config 'database') in
    
    # Use sqlite
    sqlite)
        sed -i "1a export SQLITE=1" /home/seafile/*.sh
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
        sed -i "1a export MYSQL_HOST=$(bashio::services 'mysql' 'host')" /home/seafile/*.sh
        sed -i "1a export MYSQL_PORT=$(bashio::services 'mysql' 'port')" /home/seafile/*.sh
        sed -i "1a export MYSQL_USER=$(bashio::services "mysql" "username")" /home/seafile/*.sh
        sed -i "1a export MYSQL_USER_PASSWD=$(bashio::services "mysql" "password")" /home/seafile/*.sh
        sed -i "1a export MYSQL_ROOT_PASSWD=$(bashio::services "mysql" "password")" /home/seafile/*.sh

        bashio::log.warning "This addon is using the Maria DB addon"
        bashio::log.warning "Please ensure this is included in your backups"
        bashio::log.warning "Uninstalling the MariaDB addon will remove any data"
    ;;
esac

##############
# LAUNCH APP #
##############

bashio::log.info "Starting app"
/./docker_entrypoint.sh
