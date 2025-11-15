#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# Set structure #
#################

mkdir -p /config/storage
cp -rf /var/www/html/storage/* /config/storage/
rm -r /var/www/html/storage
ln -sf /config/storage /var/www/html/storage
chown -R www-data:www-data /config

###################
# Define database #
###################

database="$(bashio::config 'database')"
bashio::log.info "Data selected : $database"

case "$database" in

    # Use sqlite
    sqlite)
        DB_DATABASE="/config/database.sqlite"
        export DB_DATABASE
        DB_CONNECTION=sqlite
        export DB_CONNECTION
        touch "$DB_DATABASE"
        mkdir -p /var/www/html/database
        ln -sf "$DB_DATABASE" /var/www/html/database/database.sqlite
        chown www-data:www-data "$DB_DATABASE"
        bashio::log.blue "Using $DB_DATABASE"
        ;;

    # Use Mariadb_addon
    MariaDB_addon)
        # Use MariaDB
        DB_CONNECTION=mysql
        export DB_CONNECTION
        bashio::log.green "Using MariaDB addon. Requirements: running MariaDB addon. Discovering values..."
        if ! bashio::services.available 'mysql'; then
            bashio::log.fatal "Local database access should be provided by the MariaDB addon"
            bashio::exit.nok "Please ensure it is installed and started"
        fi

        # Use values
        DB_HOST=$(bashio::services "mysql" "host") && bashio::log.blue "DB_HOST=$DB_HOST" && sed -i "1a export DB_HOST=$DB_HOST" /usr/local/bin/entrypoint.sh
        DB_PORT=$(bashio::services "mysql" "port") && bashio::log.blue "DB_PORT=$DB_PORT" && sed -i "1a export DB_PORT=$DB_PORT" /usr/local/bin/entrypoint.sh
        DB_DATABASE=monica && bashio::log.blue "DB_DATABASE=$DB_DATABASE" && sed -i "1a export DB_DATABASE=$DB_DATABASE" /usr/local/bin/entrypoint.sh
        DB_USERNAME=$(bashio::services "mysql" "username") && bashio::log.blue "DB_USERNAME=$DB_USERNAME" && sed -i "1a export DB_USERNAME=$DB_USERNAME" /usr/local/bin/entrypoint.sh
        DB_PASSWORD=$(bashio::services "mysql" "password") && bashio::log.blue "DB_PASSWORD=$DB_PASSWORD" && sed -i "1a export DB_PASSWORD=$DB_PASSWORD" /usr/local/bin/entrypoint.sh
        export DB_HOST
        export DB_PORT
        export DB_DATABASE
        export DB_USERNAME
        export DB_PASSWORD

        bashio::log.warning "Monica is using the MariaDB addon"
        bashio::log.warning "Please ensure this is included in your backups"
        bashio::log.warning "Uninstalling the MariaDB addon will remove any data"

        # Create database
        mysql --host="$DB_HOST" --port="$DB_PORT" --user="$DB_USERNAME" --password="$DB_PASSWORD" -e"CREATE DATABASE IF NOT EXISTS $DB_DATABASE;"

        ;;

    # Use Mariadb_addon
    Mysql_external)
        DB_CONNECTION=mysql
        export DB_CONNECTION
        for var in DB_DATABASE DB_HOST DB_PASSWORD DB_PORT DB_USERNAME; do
            # Verify all variables are set
            if ! bashio::config.has_value "$var"; then
                bashio::log.fatal "You have selected to not use the automatic MariaDB detection by manually configuring the addon options, but the option $var is not set."
                exit 1
            fi
            "$var=$(bashio::config "var")"
            export "${var?}"
            bashio::log.blue "$var=$(bashio::config "var")"
        done
        # Alert if MariaDB is available
        if bashio::services.available 'mysql'; then
            bashio::log.warning "The MariaDB addon is available, but you have selected to use your own database by manually configuring the addon options"
        fi

        # Create database
        mysql --host="$DB_HOST" --port="$DB_PORT" --user="$DB_USERNAME" --password="$DB_PASSWORD" -e"CREATE DATABASE IF NOT EXISTS $DB_DATABASE;"

        ;;

esac

###########
# APP_KEY #
###########

# Get APP_KEY from bashio::config
APP_KEY=$(bashio::config "APP_KEY")

# Check if APP_KEY is not 32 characters long
if [ -z "$APP_KEY" ] || [ ${#APP_KEY} -lt 32 ]; then
    APP_KEY="$(
        echo -n 'base64:'
        openssl rand -base64 32
    )"
    bashio::addon.option "APP_KEY" "${APP_KEY}"
    bashio::log.warning "The APP_KEY set was invalid, generated a random one: ${APP_KEY}. Restarting to take it into account"
    echo "${APP_KEY}" >> /config/APP_KEY
    bashio::addon.restart
fi
APP_KEY="$(bashio::config "APP_KEY")"
export APP_KEY

bashio::log.info "Preparing Meilisearch"
MEILISEARCH_URL="${MEILISEARCH_URL:-http://127.0.0.1:7700}"
export MEILISEARCH_URL

MEILISEARCH_URI="${MEILISEARCH_URL#*://}"
MEILISEARCH_HOST_PORT="${MEILISEARCH_URI%%/*}"
MEILISEARCH_HOST="${MEILISEARCH_HOST_PORT%%:*}"
MEILISEARCH_PORT="${MEILISEARCH_HOST_PORT##*:}"
if [ "${MEILISEARCH_PORT}" = "${MEILISEARCH_HOST_PORT}" ]; then
    MEILISEARCH_PORT=""
fi

MEILISEARCH_LOCAL=false
if [[ -n "${MEILISEARCH_PORT}" && ! ${MEILISEARCH_PORT} =~ ^[0-9]+$ ]]; then
    bashio::log.warning "Ignoring bundled Meilisearch because MEILISEARCH_URL uses a non-numeric port (${MEILISEARCH_PORT})."
elif [[ "${MEILISEARCH_HOST}" =~ ^(127\.0\.0\.1|localhost)$ ]]; then
    MEILISEARCH_LOCAL=true
    if [ -z "${MEILISEARCH_PORT}" ]; then
        MEILISEARCH_PORT="7700"
    fi
    MEILISEARCH_ADDR="${MEILISEARCH_HOST}:${MEILISEARCH_PORT}"
else
    MEILISEARCH_ADDR="127.0.0.1:7700"
fi

if [[ "${MEILISEARCH_LOCAL}" == true ]]; then
    bashio::log.info "Starting bundled Meilisearch instance at ${MEILISEARCH_ADDR}"
    MEILISEARCH_DB_PATH="/data/meilisearch"
    mkdir -p "${MEILISEARCH_DB_PATH}"

    MEILISEARCH_ENV_KEY="${MEILISEARCH_KEY:-}"
    MEILISEARCH_ENVIRONMENT="${MEILI_ENV:-production}"
    MEILISEARCH_NO_ANALYTICS="${MEILI_NO_ANALYTICS:-true}"

    S6_SUPERVISED_DIR="/run/s6/services"
    if [ ! -d "${S6_SUPERVISED_DIR}" ]; then
        S6_SUPERVISED_DIR="/var/run/s6/services"
    fi

    MEILISEARCH_CMD=(
        env \
            MEILI_ENV="${MEILISEARCH_ENVIRONMENT}" \
            MEILI_NO_ANALYTICS="${MEILISEARCH_NO_ANALYTICS}" \
            meilisearch \
            --http-addr "${MEILISEARCH_ADDR}" \
            --db-path "${MEILISEARCH_DB_PATH}"
    )

    if [ -n "${MEILISEARCH_ENV_KEY}" ]; then
        MEILISEARCH_CMD+=(--master-key "${MEILISEARCH_ENV_KEY}")
    fi

    "${MEILISEARCH_CMD[@]}" &
    MEILISEARCH_PID=$!

    (
        set +e
        wait "${MEILISEARCH_PID}"
        exit_code=$?
        set -e
        if [ "${exit_code}" -ne 0 ]; then
            bashio::log.error "Meilisearch exited unexpectedly (code ${exit_code}). Stopping add-on."
            s6-svscanctl -t "${S6_SUPERVISED_DIR}"
        fi
    ) &

    bashio::log.info "Waiting for Meilisearch TCP socket"
    bashio::net.wait_for "${MEILISEARCH_ADDR%:*}" "${MEILISEARCH_ADDR#*:}"

    bashio::log.info "Waiting for Meilisearch health endpoint"
    MEILISEARCH_HEALTH_URL="${MEILISEARCH_URL%/}/health"
    for attempt in $(seq 1 30); do
        if curl -fs "${MEILISEARCH_HEALTH_URL}" | grep -q '"status":"available"'; then
            bashio::log.info "Meilisearch is ready"
            break
        fi
        sleep 1
        if [ "${attempt}" -eq 30 ]; then
            bashio::log.error "Meilisearch did not become ready in time. Stopping add-on."
            s6-svscanctl -t "${S6_SUPERVISED_DIR}"
            exit 1
        fi
    done
else
    bashio::log.info "Detected external Meilisearch endpoint (${MEILISEARCH_URL}); skipping bundled service startup"
fi

bashio::log.info "Starting Monica"

entrypoint.sh apache2-foreground
