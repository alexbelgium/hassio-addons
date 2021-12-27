#!/usr/bin/env bashio

bashio::log.info "Launching app"

#######################
# Backup APP_KEY file #
#######################
bashio::log.info "Backuping APP_KEY to /config/addons_config/fireflyiii/APP_KEY_BACKUP.txt"
APP_KEY="$(bashio::config 'APP_KEY')"
echo "$APP_KEY" >/config/addons_config/fireflyiii/APP_KEY_BACKUP.txt
if [ ! ${#APP_KEY} = 32 ]; then bashio::exit.nok "Your APP_KEY has ${#APP_KEY} instead of 32 characters"; fi

###################
# Define database #
###################

bashio::log.info "Defining database"
case $(bashio::config 'DB_CONNECTION') in

# Use sqlite
sqlite_internal)
    bashio::log.info "Using built in sqlite"
    # Set variable
    export DB_CONNECTION=sqlite
    # Creating database
    mkdir -p /config/addons_config/fireflyiii/database
    touch /config/addons_config/fireflyiii/database/database.sqlite
    # Symlink
    rm -r /var/www/html/storage/database
    ln -sf /config/addons_config/fireflyiii/database /var/www/html/storage
    ;;

# Use MariaDB
mariadb_addon)
    bashio::log.info "Using MariaDB addon. Requirements : running MariaDB addon"
    if ! bashio::services.available 'mysql'; then
        bashio::log.fatal \
            "Local database access should be provided by the MariaDB addon"
        bashio::exit.nok \
            "Please ensure it is installed and started"
    fi

    export DB_CONNECTION=mysql
    host=$(bashio::services "mysql" "host")
    password=$(bashio::services "mysql" "password")
    port=$(bashio::services "mysql" "port")
    username=$(bashio::services "mysql" "username")

    bashio::log.warning "Firefly-iii is using the Maria DB addon"
    bashio::log.warning "Please ensure this is included in your backups"
    bashio::log.warning "Uninstalling the MariaDB addon will remove any data"

    bashio::log.info "Creating database for Firefly-iii if required"
    mysql \
        -u "${username}" -p"${password}" \
        -h "${host}" -P "${port}" \
        -e "CREATE DATABASE IF NOT EXISTS \`firefly\` ;"
    ;;

# Use remote
*)
    bashio::log.info "Using remote database. Requirement : filling all addon options fields"
    for conditions in "DB_HOST" "DB_PORT" "DB_DATABASE" "DB_USERNAME" "DB_PASSWORD"; do
        if ! bashio::config.has_value "$conditions"; then
            bashio::exit.nok "Remote database has been specified but $conditions is not defined in addon options"
        fi
    done
    ;;

esac

# Install database
php artisan migrate --seed
php artisan firefly-iii:upgrade-database

##############
# LAUNCH APP #
##############

/./usr/local/bin/entrypoint.sh
