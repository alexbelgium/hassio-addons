#!/usr/bin/env bashio
# shellcheck shell=bash
set -e
# hadolint ignore=SC2155

########
# Init #
########

# APP_KEY
APP_KEY="$(bashio::config 'APP_KEY')"

# If not base64
if [[ $APP_KEY != *"base64"*     ]]; then
    # Check APP_KEY format
    if [ ! "${#APP_KEY}" = 32 ]; then bashio::exit.nok "Your APP_KEY has ${#APP_KEY} instead of 32 characters"; fi
fi

# Backup APP_KEY file
bashio::log.info "Backuping APP_KEY to /config/addons_config/fireflyiii/APP_KEY_BACKUP.txt"
bashio::log.warning "Changing this value will require to reset your database"

# Get current app_key
mkdir -p /config/addons_config/fireflyiii
touch /config/addons_config/fireflyiii/APP_KEY_BACKUP.txt
CURRENT=$(sed -e '/^[<blank><tab>]*$/d' /config/addons_config/fireflyiii/APP_KEY_BACKUP.txt | sed -n -e '$p')

# Save if new
if [ "$CURRENT" != "$APP_KEY" ]; then
    echo "$APP_KEY" >>/config/addons_config/fireflyiii/APP_KEY_BACKUP.txt
fi

# Update permissions
mkdir -p /config/addons_config/fireflyiii
chown -R www-data:www-data /config/addons_config/fireflyiii
chown -R www-data:www-data /var/www/html/storage
chmod -R 775 /config/addons_config/fireflyiii

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
        export DB_DATABASE=/config/addons_config/fireflyiii/database/database.sqlite

        # Creating folders
        mkdir -p /config/addons_config/fireflyiii/database
        chown -R www-data:www-data /config/addons_config/fireflyiii/database

        # Creating database
        if [ ! -f /config/addons_config/fireflyiii/database/database.sqlite ]; then
            # Create database
            touch /config/addons_config/fireflyiii/database/database.sqlite
            # Install database
            echo "updating database"
            php artisan migrate:refresh --seed --quiet
            php artisan firefly-iii:upgrade-database --quiet
            php artisan passport:install --quiet
    fi

        # Creating symlink
        rm -r /var/www/html/storage/database
        ln -s /config/addons_config/fireflyiii/database /var/www/html/storage

        # Updating permissions
        chmod 775 /config/addons_config/fireflyiii/database/database.sqlite
        chown -R www-data:www-data /config/addons_config/fireflyiii
        chown -R www-data:www-data /var/www/html/storage
        ;;

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
        DB_HOST=$(bashio::services "mysql" "host")
        DB_PORT=$(bashio::services "mysql" "port")
        DB_DATABASE=firefly
        DB_USERNAME=$(bashio::services "mysql" "username")
        DB_PASSWORD=$(bashio::services "mysql" "password")
        export DB_CONNECTION
        export DB_HOST && bashio::log.blue "DB_HOST=$DB_HOST"
        export DB_PORT && bashio::log.blue "DB_PORT=$DB_PORT"
        export DB_DATABASE && bashio::log.blue "DB_DATABASE=$DB_DATABASE"
        export DB_USERNAME && bashio::log.blue "DB_USERNAME=$DB_USERNAME"
        export DB_PASSWORD && bashio::log.blue "DB_PASSWORD=$DB_PASSWORD"

        bashio::log.warning "Firefly-iii is using the Maria DB addon"
        bashio::log.warning "Please ensure this is included in your backups"
        bashio::log.warning "Uninstalling the MariaDB addon will remove any data"

        bashio::log.info "Creating database for Firefly-iii if required"
        mysql \
            -u "${DB_USERNAME}" -p"${DB_PASSWORD}" \
            -h "${DB_HOST}" -P "${DB_PORT}" \
            -e 'CREATE DATABASE IF NOT EXISTS `firefly` ;'
        ;;

        # Use remote
    *)
        bashio::log.info "Using remote database. Requirement : filling all addon options fields, and making sure the database already exists"
        for conditions in "DB_HOST" "DB_PORT" "DB_DATABASE" "DB_USERNAME" "DB_PASSWORD"; do
            if ! bashio::config.has_value "$conditions"; then
                bashio::exit.nok "Remote database has been specified but $conditions is not defined in addon options"
      fi
    done
        ;;

esac

########################
# Define upload folder #
########################

bashio::log.info "Defining upload folder"

# Creating folder
if [ ! -d /config/addons_config/fireflyiii/upload ]; then
    mkdir -p /config/addons_config/fireflyiii/upload
    chown -R www-data:www-data /config/addons_config/fireflyiii/upload
fi

# Creating symlink
if [ -d /var/www/html/storage/ha_upload ]; then
    rm -r /var/www/html/storage/ha_upload
fi
ln -s /config/addons_config/fireflyiii/upload /var/www/html/storage/ha_upload

# Updating permissions
chown -R www-data:www-data /config/addons_config/fireflyiii
chown -R www-data:www-data /var/www/html/storage
chmod -R 775 /config/addons_config/fireflyiii

# Test
f=/config/addons_config/fireflyiii
while [[ $f != / ]]; do
                        chmod 777 "$f"
                                        f=$(dirname "$f")
done

################
# CRON OPTIONS #
################

if bashio::config.has_value 'Updates'; then
    # Align update with options
    echo ""
    FREQUENCY=$(bashio::config 'Updates')
    bashio::log.info "$FREQUENCY updates"
    echo ""

    # Sets cron // do not delete this message
    cp /templates/cronupdate /etc/cron."${FREQUENCY}"/
    chmod 777 /etc/cron."${FREQUENCY}"/cronupdate

    # Sets cron to run with www-data user
    # sed -i 's|root|www-data|g' /etc/crontab

    # Starts cron
    service cron start
fi

##############
# LAUNCH APP #
##############

bashio::log.info "Please wait while the app is loading !"

if bashio::config.true 'silent'; then
    bashio::log.warning "Silent mode activated. Only errors will be shown. Please disable in addon options if you need to debug"
    sudo -Eu www-data bash -c 'cd /var/www/html && /scripts/11-execute-things.sh >/dev/null'
else
    sudo -Eu www-data bash -c 'cd /var/www/html && /scripts/11-execute-things.sh'
fi
