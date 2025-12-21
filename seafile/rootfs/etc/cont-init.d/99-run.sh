#!/usr/bin/env bashio
# shellcheck shell=bash
# shellcheck disable=SC2155,SC2016
set -e

###################################
# Export all addon options as env #
###################################

bashio::log.info "Setting variables"

# For all keys in options.json
JSONSOURCE="/data/options.json"

# Export keys as env variables
# echo "All addon options were exported as variables"
mapfile -t arr < <(jq -r 'keys[]' "${JSONSOURCE}")

for KEYS in "${arr[@]}"; do
    # export key
    VALUE=$(jq ."$KEYS" "${JSONSOURCE}")
    line="${KEYS}='${VALUE//[\"\']/}'"
    # text
    if bashio::config.false "verbose" || [[ "${KEYS}" == *"PASS"* ]]; then
        bashio::log.blue "${KEYS}=******"
    else
        bashio::log.blue "$line"
    fi
    # Use locally
    export "${KEYS}=${VALUE//[\"\']/}"
    # Export the variable to run scripts
    sed -i "1a export $line" /home/seafile/*.sh 2> /dev/null
    find /opt/seafile -name '*.sh' -print0 | xargs -0 sed -i "1a export $line"
done

#################
# DATA_LOCATION #
#################

bashio::log.info "Setting data location"
DATA_LOCATION=$(bashio::config 'data_location')

echo "... check $DATA_LOCATION folder exists"
mkdir -p "$DATA_LOCATION"

echo "... setting permissions"
chown -R seafile:seafile "$DATA_LOCATION"

echo "... copy media files"
#cp -rnf /opt/seafile/media/* "$DATA_LOCATION"/media
#rm -r /opt/seafile/media

#echo "... creating symlink"
#dirs=("conf" "logs" "media" "seafile-data" "seahub-data" "sqlite")
#for dir in "${dirs[@]}"
#do
#   mkdir -p "$DATA_LOCATION/$dir"
#   chown -R seafile:seafile "$DATA_LOCATION/$dir"
#    ln -fs "$DATA_LOCATION/$dir" /shared
#    rm /shared/"$dir"
#done

echo "... correcting official script"
sed -i "s|/shared|$DATA_LOCATION|g" /docker_entrypoint.sh
sed -i "s|/shared|$DATA_LOCATION|g" /home/seafile/*.sh
#sed -i "s=cp -r ./media $DATA_LOCATION/=chown -R seafile:seafile $DATA_LOCATION/* && chmod -R 777 $DATA_LOCATION/media && cp -rnf ./media/. $DATA_LOCATION/media ||true=g" /home/seafile/*.sh

#############################################
# Configure service URL and file server root #
#############################################

bashio::log.info "Configuring Seafile URLs"

SERVER_IP_CONFIG=$(bashio::config 'SERVER_IP')
SERVICE_URL_CONFIG=$(bashio::config 'url')
FILE_SERVER_ROOT_CONFIG=$(bashio::config 'FILE_SERVER_ROOT')
FILE_PORT_CONFIG=$(bashio::config 'PORT')

DEFAULT_HOST=${SERVER_IP_CONFIG:-homeassistant.local}
DEFAULT_FILE_PORT=${FILE_PORT_CONFIG:-8082}

normalize_url() {
    local raw_url="${1%/}"
    local default_scheme="$2"

    if [[ -z "${raw_url}" || "${raw_url}" == "null" ]]; then
        echo ""
        return
    fi

    if [[ "${raw_url}" =~ ^https?:// ]]; then
        echo "${raw_url}"
    else
        echo "${default_scheme}://${raw_url}"
    fi
}

SERVICE_URL_VALUE=$(normalize_url "${SERVICE_URL_CONFIG:-${DEFAULT_HOST}:8000}" "http")
FILE_SERVER_ROOT_VALUE=$(normalize_url "${FILE_SERVER_ROOT_CONFIG:-${DEFAULT_HOST}:${DEFAULT_FILE_PORT}}" "http")

SEAHUB_SETTINGS_FILE="${DATA_LOCATION}/conf/seahub_settings.py"
mkdir -p "$(dirname "${SEAHUB_SETTINGS_FILE}")"
touch "${SEAHUB_SETTINGS_FILE}"

sed -i '/^SERVICE_URL *=/d' "${SEAHUB_SETTINGS_FILE}"
sed -i '/^FILE_SERVER_ROOT *=/d' "${SEAHUB_SETTINGS_FILE}"

{
    echo "SERVICE_URL = \"${SERVICE_URL_VALUE}\""
    echo "FILE_SERVER_ROOT = \"${FILE_SERVER_ROOT_VALUE}\""
} >> "${SEAHUB_SETTINGS_FILE}"

bashio::log.info "SERVICE_URL set to ${SERVICE_URL_VALUE}"
bashio::log.info "FILE_SERVER_ROOT set to ${FILE_SERVER_ROOT_VALUE}"

###################
# Define database #
###################

bashio::log.info "Defining database"

# The option is defined as a list, so grab the first entry when an array is
# provided (Home Assistant stores multi-select options this way). Fallback to
# the raw value to stay compatible with older configurations that used a
# string.
DATABASE_SELECTION=$(bashio::config 'database[0]' 2>/dev/null || true)
DATABASE_SELECTION=${DATABASE_SELECTION:-$(bashio::config 'database')}

case "${DATABASE_SELECTION}" in

    # Use sqlite
    sqlite)
        export "SQLITE=1" && sed -i "1a export SQLITE=1" /home/seafile/*.sh
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
        export MYSQL_HOST="$(bashio::services 'mysql' 'host')" && sed -i "1a export MYSQL_HOST=$(bashio::services 'mysql' 'host')" /home/seafile/*.sh
        export MYSQL_PORT="$(bashio::services 'mysql' 'port')" && sed -i "1a export MYSQL_PORT=$(bashio::services 'mysql' 'port')" /home/seafile/*.sh
        export MYSQL_USER="$(bashio::services "mysql" "username")" && sed -i "1a export MYSQL_USER=$(bashio::services 'mysql' 'username')" /home/seafile/*.sh
        export MYSQL_USER_PASSWD="$(bashio::services "mysql" "password")" && sed -i "1a export MYSQL_USER_PASSWD=$(bashio::services 'mysql' 'password')" /home/seafile/*.sh
        export MYSQL_ROOT_PASSWD="$(bashio::services "mysql" "password")" && sed -i "1a export MYSQL_ROOT_PASSWD=$(bashio::services 'mysql' 'password')" /home/seafile/*.sh

        # Mariadb requires a user
        echo "Adapting scripts"
        sed -i 's|port=${MYSQL_PORT})|port=${MYSQL_PORT}, user="${MYSQL_USER}")|g' /home/seafile/wait_for_db.sh

        # Mariadb has no root user
        echo "Adapting root name"
        sed -i 's|user="root"|user="service"|g' /home/seafile/clean_db.sh
        sed -i "s|'root'|'service'|g" /opt/seafile/*/setup-seafile-mysql.sh
        sed -i "s|'root'|'service'|g" /opt/seafile/*/setup-seafile-mysql.py

        # Informations
        bashio::log.warning "This addon is using the Maria DB addon"
        bashio::log.warning "Please ensure this is included in your backups"
        bashio::log.warning "Uninstalling the MariaDB addon will remove any data"
        ;;
esac

##############
# LAUNCH APP #
##############

bashio::log.info "Starting app"
/./docker_entrypoint.sh launch
