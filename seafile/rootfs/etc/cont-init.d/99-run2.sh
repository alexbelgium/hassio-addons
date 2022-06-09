#!/usr/bin/env bashio

exit 0

#################
# DATA LOCATION #
#################

DATA_LOCATION="$(bashio::config 'data_location')"

# Chack Seafile dir
bashio::log.info "Making data folder $DATA_LOCATION"

# Make dir
echo "Checking location exists"
mkdir -p "$DATA_LOCATION"

# Make dir
echo "Checking permissions"
chown -R "$(id -u)":"$(id -g)" "$DATA_LOCATION"
chmod -R 755 "$DATA_LOCATION"

# Create symlink
echo "Checking symlink"
ln -fs "$DATA_LOCATION" /shared

####################
# GLOBAL VARIABLES #
####################

echo "Exporting variables"
export SEAFILE_SERVER_LETSENCRYPT="$(bashio::config 'seafile_server_letsencrypt')"
export SEAFILE_SERVER_HOSTNAME="$(bashio::config 'seafile_server_hostname')"
export SEAFILE_ADMIN_EMAIL="$(bashio::config 'seafile_admin_email')"
export SEAFILE_ADMIN_PASSWORD="$(bashio::config 'seafile_admin_password')"
bashio::log.blue "SEAFILE_SERVER_LETSENCRYPT=$SEAFILE_SERVER_LETSENCRYPT"
bashio::log.blue "SEAFILE_SERVER_HOSTNAME=$SEAFILE_SERVER_HOSTNAME"
bashio::log.blue "SEAFILE_ADMIN_EMAIL=$SEAFILE_ADMIN_EMAIL"
bashio::log.blue "SEAFILE_ADMIN_PASSWORD=$SEAFILE_ADMIN_PASSWORD"

###################
# Define database #
###################

bashio::log.info "Defining database"
case $(bashio::config 'database') in

    # Use sqlite
    sqlite)
        bashio::log.info "Using a local sqlite database"
        ehco "Installing sqlite"
        apt-get update &>/dev/null \
      	apt-get install -y sqlite3 &>/dev/null  \
	      apt-get clean &>/dev/null 

        echo "Configuring sqlite"
        sed -i 's/setup-seafile-mysql\.sh/setup-seafile.sh/g' /scripts/bootstrap.py \
        && sed -i '/def wait_for_mysql()/a\\    return' /scripts/utils.py \
        && touch $DATA_LOCATION/seahub.db \
        && ln -fs "$DATA_LOCATION/seahub.db" /opt/seafile
        
        export SEAFILE_ADMIN_EMAIL=test@test.test
        export SEAFILE_ADMIN_PASSWORD=gf7Ads¤f#B2G
        export SEAFILE_SERVER_HOSTNAME=seafile.test
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
        export MYSQL_SERVER=$(bashio::services "mysql" "host") && bashio::log.blue "MYSQL_SERVER=$MYSQL_SERVER"
        export MYSQL_PORT=$(bashio::services "mysql" "port") && bashio::log.blue "MYSQL_PORT=$MYSQL_PORT"
        export MYSQL_USER=$(bashio::services "mysql" "username") && bashio::log.blue "MYSQL_USER=$MYSQL_USER"
        export MYSQL_PORT=$(bashio::services "mysql" "password") && bashio::log.blue "MYSQL_PORT=$MYSQL_PORT"

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
