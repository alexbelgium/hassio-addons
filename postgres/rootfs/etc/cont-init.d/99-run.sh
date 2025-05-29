#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

CONFIG_HOME="/config"
PGDATA="${PGDATA:-/config/database}"
export PGDATA
PG_VERSION_FILE="$PGDATA/pg_major_version"

PG_MAJOR_VERSION="${PG_MAJOR:-15}"

mkdir -p "$PGDATA"
chown -R postgres:postgres "$PGDATA"
chmod 700 "$PGDATA"
chmod -R 755 "$CONFIG_HOME"

RESTART_NEEDED=false

cd /config || true

bashio::log.info "Starting PostgreSQL..."

if [ "$(bashio::info.arch)" = "armv7" ]; then
    bashio::log.warning "ARMv7 detected: Starting without vectors.so"
    /usr/local/bin/immich-docker-entrypoint.sh postgres & true
    exit 0
else
    /usr/local/bin/immich-docker-entrypoint.sh postgres -c config_file=/etc/postgresql/postgresql.conf & true
fi

bashio::log.info "Waiting for PostgreSQL to start..."

(
bashio::net.wait_for 5432 localhost 900

DB_PORT=5432
DB_HOSTNAME=localhost
DB_PASSWORD="$(bashio::config 'POSTGRES_PASSWORD')"
DB_PASSWORD="$(jq -rn --arg x "$DB_PASSWORD" '$x|@uri')"
DB_USERNAME=postgres
if bashio::config.has_value "POSTGRES_USER"; then
    DB_USERNAME="$(bashio::config "POSTGRES_USER")"
fi
export DB_PORT DB_HOSTNAME DB_USERNAME DB_PASSWORD

until pg_isready -h "$DB_HOSTNAME" -p "$DB_PORT" -U "$DB_USERNAME" >/dev/null 2>&1; do
    echo "PostgreSQL is starting up..."
    sleep 2
done

update_postgres() {
    OLD_PG_VERSION=$(cat "$PG_VERSION_FILE" 2>/dev/null || echo "$PG_MAJOR_VERSION")
    if [ "$OLD_PG_VERSION" != "$PG_MAJOR_VERSION" ]; then
        bashio::log.warning "PostgreSQL major version changed ($OLD_PG_VERSION → $PG_MAJOR_VERSION). Running upgrade..."

        export DATA_DIR="$PGDATA"
        export BINARIES_DIR="/usr/lib/postgresql/$PG_MAJOR_VERSION/bin"
        export BACKUP_DIR="/config/backups"
        export PSQL_VERSION="$PG_MAJOR_VERSION"

        apt-get update &>/dev/null
        apt-get install -y procps rsync postgresql-$PG_MAJOR_VERSION postgresql-$OLD_PG_VERSION &>/dev/null

        TMP_SCRIPT=$(mktemp)
        wget https://raw.githubusercontent.com/linkyard/postgres-upgrade/refs/heads/main/upgrade-postgres.sh -O "$TMP_SCRIPT"
        chmod +x "$TMP_SCRIPT"
        "$TMP_SCRIPT"

        echo "$PG_MAJOR_VERSION" > "$PG_VERSION_FILE"
        bashio::log.info "PostgreSQL major version upgrade complete."
        RESTART_NEEDED=true
    fi
}

get_available_extension_version() {
    local extname="$1"
    psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT/postgres" -tAc \
        "SELECT default_version FROM pg_available_extensions WHERE name = '$extname';" 2>/dev/null | xargs
}

is_extension_available() {
    local extname="$1"
    local result
    result=$(psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT/postgres" -tAc \
        "SELECT 1 FROM pg_available_extensions WHERE name = '$extname';" 2>/dev/null | xargs)
    [[ "$result" == "1" ]]
}

get_user_databases() {
    psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT/postgres" -tAc \
        "SELECT datname FROM pg_database WHERE datistemplate = false AND datallowconn = true;"
}

get_installed_extension_version() {
    local extname="$1"
    local dbname="$2"
    psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT/$dbname" -tAc \
        "SELECT extversion FROM pg_extension WHERE extname = '$extname';" 2>/dev/null | xargs
}

compare_versions() {
    # Compares version strings (e.g., 0.3.0 vs 0.4.0)
    if [ "$1" = "$2" ]; then
        return 1 # Same
    fi
    # Split version by dots and compare segments
    IFS=. read -r a1 a2 a3 <<<"$1"
    IFS=. read -r b1 b2 b3 <<<"$2"
    if [ "$a1" -lt "$b1" ]; then return 0; fi
    if [ "$a1" -gt "$b1" ]; then return 1; fi
    if [ "$a2" -lt "$b2" ]; then return 0; fi
    if [ "$a2" -gt "$b2" ]; then return 1; fi
    if [ "$a3" -lt "$b3" ]; then return 0; fi
    return 1
}

upgrade_extension_if_needed() {
    local extname="$1"
    if ! is_extension_available "$extname"; then
        bashio::log.info "$extname extension not available on this Postgres instance."
        return
    fi
    local available_version
    available_version=$(get_available_extension_version "$extname")
    if [ -z "$available_version" ]; then
        bashio::log.info "Could not determine available version for $extname."
        return
    fi
    for db in $(get_user_databases); do
        local installed_version
        installed_version=$(get_installed_extension_version "$extname" "$db")
        if [ -n "$installed_version" ]; then
            compare_versions "$installed_version" "$available_version"
            if [ $? -eq 0 ]; then
                bashio::log.info "Upgrading $extname in $db from $installed_version to $available_version"
                psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT/$db" -c "ALTER EXTENSION $extname UPDATE;" \
                    && RESTART_NEEDED=true \
                    || bashio::log.warning "Failed to upgrade $extname in $db"
            else
                bashio::log.info "$extname in $db already at latest version ($installed_version)"
            fi
        fi
    done
}

update_postgres

upgrade_extension_if_needed "vectors"
upgrade_extension_if_needed "vchord"

if [ "$RESTART_NEEDED" = true ]; then
    bashio::log.warning "A critical update (Postgres or extension) occurred. Restarting the addon for changes to take effect."
    bashio::addon.restart
    exit 0
fi

bashio::log.info "All initialization/version check steps completed successfully!"
) & true
