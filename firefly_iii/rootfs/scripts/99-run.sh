#!/usr/bin/env bashio

bashio::log.info "Launching app"

# Backup API_KEY file
bashio::log.info "Backuping API_KEY to /config/addons_config/fireflyiii/API_KEY_BACKUP.txt"
API_KEY="$(bashio::config 'API_KEY')"
echo "$API_KEY" >/config/addons_config/fireflyiii/API_KEY_BACKUP.txt
if [ ! ${#API_KEY} = 32 ]; then bashio::exit.nok "Your API_KEY has ${#API_KEY} instead of 32 characters"; fi

# Define database
bashio::log.info "Defining database"
case $(bashio::config 'DB_CONNECTION') in

# Use sqlite
sqlite_internal)
    bashio::log.info "Using built in sqlite"
    touch ./storage/database/database.sqlite
    php artisan migrate --seed
    php artisan firefly-iii:upgrade-database
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

##############
# LAUNCH APP #
##############

/./usr/local/bin/entrypoint.sh
