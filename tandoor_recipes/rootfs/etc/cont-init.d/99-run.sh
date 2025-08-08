#!/usr/bin/bashio
# shellcheck shell=bash
# shellcheck disable=SC2155
set -e

#####################
# Export env values #
#####################

export ALLOWED_HOSTS=$(bashio::config 'ALLOWED_HOSTS') && bashio::log.blue "ALLOWED_HOSTS=$ALLOWED_HOSTS"
export SECRET_KEY=$(bashio::config 'SECRET_KEY') && bashio::log.blue "SECRET_KEY=$SECRET_KEY"
export DEBUG=$(bashio::config 'DEBUG') && bashio::log.blue "DEBUG=$DEBUG"
export AI_MODEL_NAME=$(bashio::config 'AI_MODEL_NAME') && bashio::log.blue "AI_MODEL_NAME=$AI_MODEL_NAME"
export AI_API_KEY=$(bashio::config 'AI_API_KEY') && bashio::log.blue "AI_API_KEY=$AI_API_KEY"
export AI_RATELIMIT=$(bashio::config 'AI_RATELIMIT') && bashio::log.blue "AI_RATELIMIT=$AI_RATELIMIT"

CSRF_TRUSTED_ORIGINS="http://localhost"
for element in ${ALLOWED_HOSTS//,/ }; do # Separate comma separated values
    element="${element#"https://"}"
    element="${element#"http://"}"
    CSRF_TRUSTED_ORIGINS="http://$element,https://$element,$CSRF_TRUSTED_ORIGINS"
done
export CSRF_TRUSTED_ORIGINS
export ALLOWED_HOSTS="*"

#################
# Allow ingress #
#################

#sed -i "s|href=\"{% base_path request \'base\' %}\"|href=\"{% base_path request \'base\' %}/\"|g" /opt/recipes/cookbook/templates/base.html

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

        # tandoor recipes doesnt support mariadb.
        #    mariadb_addon)
        #        bashio::log.info "Using MariaDB addon. Requirements : running MariaDB addon. Discovering values..."
        #        if ! bashio::services.available 'mysql'; then
        #            bashio::log.fatal \
        #                "Local database access should be provided by the MariaDB addon"
        #            bashio::exit.nok \
        #                "Please ensure it is installed and started"
        #        fi

        # Install apps
        #        apk add --no-cache postgresql-libs gettext zlib libjpeg libxml2-dev libxslt-dev mysql-client mariadb-connector-c-dev mariadb-dev >/dev/null

        # Install mysqlclient
        #        pip install pymysql &>/dev/null

        #        export DB_ENGINE=django.db.backends.mysql
        #        export POSTGRES_HOST=$(bashio::services "mysql" "host") && bashio::log.blue "POSTGRES_HOST=$POSTGRES_HOST"
        #        export POSTGRES_PORT=$(bashio::services "mysql" "port") && bashio::log.blue "POSTGRES_PORT=$POSTGRES_PORT"
        #        export POSTGRES_USER=$(bashio::services "mysql" "username") && bashio::log.blue "POSTGRES_USER=$POSTGRES_USER"
        #        export POSTGRES_PASSWORD=$(bashio::services "mysql" "password") && bashio::log.blue "POSTGRES_PASSWORD=$POSTGRES_PASSWORD"
        #        export POSTGRES_DB="tandoor" && bashio::log.blue "POSTGRES_DB=tandoor"

        # Use values
        #        sed -i "1a export DB_ENGINE=django.db.backends.mysql" /opt/recipes/boot.sh
        #        sed -i "1a export POSTGRES_HOST=$(bashio::services "mysql" "host")" /opt/recipes/boot.sh && bashio::log.blue "POSTGRES_HOST=$POSTGRES_HOST"
        #        sed -i "1a export POSTGRES_PORT=$(bashio::services "mysql" "port")" /opt/recipes/boot.sh && bashio::log.blue "POSTGRES_PORT=$POSTGRES_PORT"
        #        sed -i "1a export POSTGRES_USER=$(bashio::services "mysql" "username")" /opt/recipes/boot.sh && bashio::log.blue "POSTGRES_USER=$POSTGRES_USER"
        #        sed -i "1a export POSTGRES_PASSWORD=$(bashio::services "mysql" "password")" /opt/recipes/boot.sh && bashio::log.blue "POSTGRES_PASSWORD=$POSTGRES_PASSWORD"
        #        sed -i "1a export POSTGRES_DB=tandoor" /opt/recipes/boot.sh && bashio::log.blue "POSTGRES_DB=tandoor"

        #        bashio::log.warning "This addon is using the Maria DB addon"
        #        bashio::log.warning "Please ensure this is included in your backups"
        #        bashio::log.warning "Uninstalling the MariaDB addon will remove any data"

        #        bashio::log.info "Creating database if required"

        #        mysql \
        #            -u "${POSTGRES_USER}" -p"${POSTGRES_PASSWORD}" \
        #            -h "${POSTGRES_HOST}" -P "${POSTGRES_PORT}" \
        #            -e "CREATE DATABASE IF NOT EXISTS \`${POSTGRES_DB}\` ;"
        #        ;;

        # use postgresql
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

if bashio::config.has_value "externalfiles_folder"; then
    externalfiles_folder="$(bashio::config "externalfiles_folder")"
else
    externalfiles_folder="/config/addons_config/tandoor_recipes/externalfiles"
fi
mkdir -p "$externalfiles_folder"
ln -s "$externalfiles_folder" /opt/recipes

bashio::log.info "Launching app"
cd /opt/recipes || exit
./boot.sh
