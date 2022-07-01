#!/usr/bin/bashio
# shellcheck shell=bash
# shellcheck disable=SC2155

#####################
# Export env values #
#####################

export ALLOWED_HOSTS=$(bashio::config 'ALLOWED_HOSTS') && bashio::log.blue "ALLOWED_HOSTS=$ALLOWED_HOSTS"
export SECRET_KEY=$(bashio::config 'SECRET_KEY') && bashio::log.blue "SECRET_KEY=$SECRET_KEY"

#################
# Allow ingress #
#################

#bashio::log.info "Setting ingress"
#ingress_entry="$(bashio::addon.ingress_entry)"
#export SCRIPT_NAME="$ingress_entry"
#export JS_REVERSE_SCRIPT_PREFIX="${ingress_entry}/"
#export STATIC_URL="${ingress_entry}/static/"
#export MEDIA_URL="${ingress_entry}/media/"

###################
# Define database #
###################

bashio::log.info "Defining database"
export DB_TYPE=$(bashio::config 'DB_TYPE')
case $(bashio::config 'DB_TYPE') in

        # Use sqlite
    sqlite)
        bashio::log.info "Using a local sqlite database"
        export DB_ENGINE="django.db.backends.sqlite3"
        export POSTGRES_DB="/config/addons_config/tandoor_recipes/recipes.db"
        ;;

    mariadb_addon)
        bashio::log.info "Using MariaDB addon. Requirements : running MariaDB addon. Discovering values..."
        if ! bashio::services.available 'mysql'; then
            bashio::log.fatal \
                "Local database access should be provided by the MariaDB addon"
            bashio::exit.nok \
                "Please ensure it is installed and started"
        fi

        # Install apps
        apk add --no-cache postgresql-libs gettext zlib libjpeg libxml2-dev libxslt-dev mysql-client mariadb-connector-c-dev mariadb-dev >/dev/null

        # Install mysqlclient
        pip install pymysql &>/dev/null

        # Use values
        export DB_ENGINE=django.db.backends.mysql
        export POSTGRES_HOST=$(bashio::services "mysql" "host") && bashio::log.blue "POSTGRES_HOST=$POSTGRES_HOST"
        export POSTGRES_PORT=$(bashio::services "mysql" "port") && bashio::log.blue "POSTGRES_PORT=$POSTGRES_PORT"
        export POSTGRES_USER=$(bashio::services "mysql" "username") && bashio::log.blue "POSTGRES_USER=$POSTGRES_USER"
        export POSTGRES_PASSWORD=$(bashio::services "mysql" "password") && bashio::log.blue "POSTGRES_PASSWORD=$POSTGRES_PASSWORD"
        export POSTGRES_DB="tandoor" && bashio::log.blue "POSTGRES_DB=tandoor"

        bashio::log.warning "This addon is using the Maria DB addon"
        bashio::log.warning "Please ensure this is included in your backups"
        bashio::log.warning "Uninstalling the MariaDB addon will remove any data"
        ;;

    postgresql_external)
        bashio::log.info "Using an external database, please populate all required fields in the addons config"
        export DB_ENGINE=django.db.backends.postgresql
        export POSTGRES_HOST=$(bashio::config "POSTGRES_HOST") && bashio::log.blue "POSTGRES_HOST=$POSTGRES_HOST"
        export POSTGRES_PORT=$(bashio::config "POSTGRES_PORT") && bashio::log.blue "POSTGRES_PORT=$POSTGRES_PORT"
        export POSTGRES_DB=$(bashio::config "POSTGRES_DB") && bashio::log.blue "POSTGRES_DB=$POSTGRES_DB"
        export POSTGRES_USER=$(bashio::config "POSTGRES_USER") && bashio::log.blue "POSTGRES_USER=$POSTGRES_USER"
        export POSTGRES_PASSWORD=$(bashio::config "POSTGRES_PASSWORD") && bashio::log.blue "POSTGRES_PASSWORD=$POSTGRES_PASSWORD"
        ;;

esac

##############
# Launch app #
##############
echo "Creating symlinks"
mkdir -p /config/addons_config/tandoor_recipes/mediafiles
chmod -R 755 /config/addons_config/tandoor_recipes
mkdir -p /data/recipes/staticfiles
chmod 755 /data/recipes/staticfiles
ln -s /config/addons_config/tandoor_recipes/mediafiles /opt/recipes
ln -s /data/recipes/staticfiles /opt/recipes

bashio::log.info "Launching nginx"
exec nginx & echo "done"

bashio::log.info "Launching app"
cd /opt/recipes || exit
./boot.sh
