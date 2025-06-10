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
    if bashio::config.false "verbose" || [[ ${KEYS} == *"PASS"*   ]]; then
        bashio::log.blue "${KEYS}=******"
  else
        bashio::log.blue "$line"
  fi
    # Use locally
    export "${KEYS}=${VALUE//[\"\']/}"
    # Export the variable to run scripts
    sed -i "1a export $line" /home/seafile/*.sh 2>/dev/null
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

###################
# Define database #
###################

bashio::log.info "Defining database"

case $(bashio::config 'database') in

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
