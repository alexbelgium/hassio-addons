#!/usr/bin/env bashio
# shellcheck shell=bash
set -euo pipefail

CONFIG_HOME="/config"
PGDATA="${PGDATA:-/config/database}"
export PGDATA
RESTART_FLAG_FILE="$CONFIG_HOME/restart_needed"
# Major whose server is started: the image's, or the cluster's own when its upgrade failed
RUN_MAJOR="$PG_MAJOR"

chmod -R 755 "$CONFIG_HOME"
cd /config || true

# Shown in Home Assistant itself: a failed upgrade must not go unnoticed in a log nobody reads
notify() {
    bashio::log.error "$1"
    curl -fsS -o /dev/null -X POST -H "Authorization: Bearer $SUPERVISOR_TOKEN" -H "Content-Type: application/json" \
        -d "$(jq -n --arg message "$1 See the log of the add-on for details." '{title: "Postgres add-on", notification_id: "postgres_addon_upgrade", message: $message}')" \
        http://supervisor/core/api/services/persistent_notification/create || true
}

# Before the server is opened to applications: brings the extensions of the cluster to the
# versions of this image and, when the cluster is from an older PostgreSQL major, upgrades it.
# The cluster is only replaced once its upgraded copy has been started and checked; when the
# upgrade fails it is left as it was and served by the PostgreSQL version it belongs to, which
# the image ships as well
prepare_cluster() {
    local rc=0
    touch /run/postgres_upgrading
    PGPASSWORD="$(bashio::config 'POSTGRES_PASSWORD')" /usr/local/bin/pg_major_upgrade.sh || rc=$?
    rm -f /run/postgres_upgrading
    case "$rc" in
        0) ;;
        10)
            # Immich does not rebuild its indexes or reconnect cleanly by itself after this
            touch "$RESTART_FLAG_FILE"
            ;;
        11)
            notify "The extensions of a database could not be updated to the versions of this add-on. PostgreSQL is started, but applications using them (Immich) may fail."
            ;;
        1)
            RUN_MAJOR="$(cat "$PGDATA/PG_VERSION")"
            notify "The upgrade of the database from PostgreSQL $RUN_MAJOR to $PG_MAJOR failed. Your data is kept as it was and PostgreSQL $RUN_MAJOR is started instead; the upgrade is tried again with the next version of the add-on."
            ;;
        *)
            notify "The database in $PGDATA cannot be used by this version of the add-on (PostgreSQL $PG_MAJOR), PostgreSQL is not started. Your data is untouched."
            exit 1
            ;;
    esac
}

start_postgres() {
    bashio::log.info "Starting PostgreSQL $RUN_MAJOR..."
    PATH="/usr/lib/postgresql/$RUN_MAJOR/bin:$PATH" /usr/local/bin/immich-docker-entrypoint.sh postgres -c config_file=/etc/postgresql/postgresql.conf &
    true
}

wait_for_postgres() {
    local tries=0
    while ! pg_isready -h "$DB_HOSTNAME" -p "$DB_PORT" -U "$DB_USERNAME" > /dev/null 2>&1; do
        tries=$((tries + 1))
        [ "$tries" -ge 60 ] && {
            bashio::log.error "Postgres did not start after 2 minutes, aborting."
            exit 1
        }
        echo "PostgreSQL is starting up... ($tries/60)"
        sleep 2
    done
}

restart_immich_addons_if_flagged() {
    [ ! -f "$RESTART_FLAG_FILE" ] && return 0
    bashio::log.warning "Detected pending Immich add‑on restart flag. Restarting all running Immich add‑ons…"

    local addons_json found=0
    addons_json=$(curl -fsSL -H "Authorization: Bearer $SUPERVISOR_TOKEN" http://supervisor/addons) || {
        bashio::log.error "Supervisor API call failed or unauthorized: $addons_json"
        rm -f "$RESTART_FLAG_FILE"
        return 1
    }

    if command -v jq > /dev/null; then
        for slug in $(echo "$addons_json" | jq -r '.addons[] | select(.state=="started") | .slug'); do
            if [[ "$slug" == *immich* ]]; then
                bashio::log.info "Restarting addon $slug"
                curl -fsSL -X POST -H "Authorization: Bearer $SUPERVISOR_TOKEN" "http://supervisor/addons/$slug/restart"
                found=1
            fi
        done
    else
        for slug in $(echo "$addons_json" | grep -o '"slug":"[^"]*"' | cut -d: -f2 | tr -d '"'); do
            if [[ "$slug" == *immich* ]]; then
                bashio::log.info "Restarting addon $slug"
                curl -fsSL -X POST -H "Authorization: Bearer $SUPERVISOR_TOKEN" "http://supervisor/addons/$slug/restart"
                found=1
            fi
        done
    fi

    [ "$found" -eq 0 ] && bashio::log.info "No Immich-related addon found running."
    rm -f "$RESTART_FLAG_FILE"
}

# ---------------------------  DB connection setup  ---------------------------
DB_PORT=5432
DB_HOSTNAME=localhost
DB_PASSWORD="$(bashio::config 'POSTGRES_PASSWORD')"
DB_PASSWORD="$(jq -rn --arg x "$DB_PASSWORD" '$x|@uri')"

if bashio::config.has_value "POSTGRES_USER"; then
    DB_USERNAME="$(bashio::config 'POSTGRES_USER')"
else
    DB_USERNAME="postgres"
fi
export DB_PORT DB_HOSTNAME DB_USERNAME DB_PASSWORD
# -----------------------------------------------------------------------------

get_user_databases() {
    psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT/postgres" -v ON_ERROR_STOP=1 -tAc \
        "SELECT datname FROM pg_database WHERE datistemplate = false AND datallowconn = true;"
}

show_db_extensions() {
    bashio::log.info "==== PostgreSQL databases and enabled extensions ===="
    for db in $(get_user_databases); do
        bashio::log.info "Database: $db"
        exts=$(psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT/$db" -tAc \
            "SELECT extname || ' (v' || extversion || ')' FROM pg_extension ORDER BY extname;")
        if [ -n "$exts" ]; then
            while read -r ext; do
                [ -n "$ext" ] && bashio::log.info "    - $ext"
            done <<< "$exts"
        else
            bashio::log.info "    (no extensions enabled)"
        fi
    done
    bashio::log.info "=============================================="
}

main() {
    bashio::log.info "Preparing the PostgreSQL cluster before server start…"
    prepare_cluster

    start_postgres
    bashio::log.info "Waiting for PostgreSQL to start…"
    wait_for_postgres
    restart_immich_addons_if_flagged
    show_db_extensions

    if [ -d /config/backups ]; then
        bashio::log.warning "/config/backups is left from an upgrade by an older version of this add-on. Delete it once you have checked that your data is complete"
    fi

    bashio::log.info "All initialization / version‑check steps completed successfully!"
}

main
