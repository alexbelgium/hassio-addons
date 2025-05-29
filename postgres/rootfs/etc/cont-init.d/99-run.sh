#!/usr/bin/env bashio
# shellcheck shell=bash
set -euo pipefail

# ----------------------- General setup -----------------------

CONFIG_HOME="/config"
PGDATA="${PGDATA:-/config/database}"
export PGDATA
PG_MAJOR_VERSION="${PG_MAJOR:-15}"
RESTART_FLAG_FILE="$CONFIG_HOME/restart_needed"

# Ensure permissions and folder structure

mkdir -p "$PGDATA"

fix_permissions(){
    chown -R postgres:postgres "$PGDATA"
    chmod 700 "$PGDATA"
}

chmod -R 755 "$CONFIG_HOME"

RESTART_NEEDED=false

cd /config || true

# ------------------ PGDATA version detection ------------------

get_pgdata_version() {
    if [ -f "$PGDATA/PG_VERSION" ]; then
        cat "$PGDATA/PG_VERSION"
    else
        bashio::log.error "FATAL: $PGDATA/PG_VERSION not found; cannot determine cluster version."
        exit 1
    fi
}

# ------------------ Cluster upgrade logic ---------------------

upgrade_postgres_if_needed() {
    CLUSTER_VERSION=$(get_pgdata_version)
    IMAGE_VERSION="$PG_MAJOR_VERSION"

    if [ "$CLUSTER_VERSION" != "$IMAGE_VERSION" ]; then
        bashio::log.warning "Postgres data directory version is $CLUSTER_VERSION but image wants $IMAGE_VERSION. Running upgrade..."

        export DATA_DIR="$PGDATA"
        export BINARIES_DIR="/usr/lib/postgresql"
        export BACKUP_DIR="/config/backups"
        export PSQL_VERSION="$IMAGE_VERSION"
        export SUPPORTED_POSTGRES_VERSIONS="$CLUSTER_VERSION $IMAGE_VERSION"

        # Ensure both old and new server binaries are present
        apt-get update &>/dev/null
        apt-get install -y procps rsync "postgresql-$IMAGE_VERSION" "postgresql-$CLUSTER_VERSION" &>/dev/null

        # Sanity checks
        if [ ! -d "$BINARIES_DIR/$CLUSTER_VERSION/bin" ]; then
            bashio::log.error "Old postgres binaries not found at $BINARIES_DIR/$CLUSTER_VERSION/bin"
            exit 1
        fi
        if [ ! -d "$BINARIES_DIR/$IMAGE_VERSION/bin" ]; then
            bashio::log.error "New postgres binaries not found at $BINARIES_DIR/$IMAGE_VERSION/bin"
            exit 1
        fi

        # Prepare backup
        mkdir -p "$BACKUP_DIR"
        backup_target="$BACKUP_DIR/postgresql-$CLUSTER_VERSION"
        bashio::log.info "Backing up data directory to $backup_target..."
        rsync -a --delete "$PGDATA/" "$backup_target/"
        if [ $? -ne 0 ]; then
            bashio::log.error "Backup with rsync failed!"
            exit 1
        fi

        fix_permissions

        # Start old Postgres
        bashio::log.info "Starting old Postgres ($CLUSTER_VERSION) to capture encoding/locale settings"
        su - postgres -c "$BINARIES_DIR/$CLUSTER_VERSION/bin/pg_ctl -w -D '$PGDATA' start"

        LC_COLLATE=$(su - postgres -c "$BINARIES_DIR/$CLUSTER_VERSION/bin/psql -d postgres -Atc 'SHOW LC_COLLATE;'")
        LC_CTYPE=$(su - postgres -c "$BINARIES_DIR/$CLUSTER_VERSION/bin/psql -d postgres -Atc 'SHOW LC_CTYPE;'")
        ENCODING=$(su - postgres -c "$BINARIES_DIR/$CLUSTER_VERSION/bin/psql -d postgres -Atc 'SHOW server_encoding;'")

        bashio::log.info "Detected cluster: LC_COLLATE=$LC_COLLATE, LC_CTYPE=$LC_CTYPE, ENCODING=$ENCODING"

        # Stop old Postgres
        bashio::log.info "Stopping old Postgres ($CLUSTER_VERSION)"
        su - postgres -c "$BINARIES_DIR/$CLUSTER_VERSION/bin/pg_ctl -w -D '$PGDATA' stop"

        fix_permissions

        # Move aside data directory
        rm -rf "$PGDATA"

        # Init new cluster
        bashio::log.info "Initializing new data cluster for $IMAGE_VERSION"
        su - postgres -c "$BINARIES_DIR/$IMAGE_VERSION/bin/initdb --encoding=$ENCODING --lc-collate=$LC_COLLATE --lc-ctype=$LC_CTYPE -D '$PGDATA'"

        fix_permissions

        # Upgrade using pg_upgrade
        bashio::log.info "Running pg_upgrade from $CLUSTER_VERSION → $IMAGE_VERSION"
        chmod 700 "$PGDATA"
        chmod 700 "$backup_target"
        su - postgres -c "$BINARIES_DIR/$IMAGE_VERSION/bin/pg_upgrade \
            -b '$BINARIES_DIR/$CLUSTER_VERSION/bin' \
            -B '$BINARIES_DIR/$IMAGE_VERSION/bin' \
            -d '$backup_target' \
            -D '$PGDATA'"

        if [ $? -ne 0 ]; then
            bashio::log.error "pg_upgrade failed!"
            exit 1
        fi

        # Copy original postgresql.conf back if needed
        if [ -f "$backup_target/postgresql.conf" ]; then
            cp "$backup_target/postgresql.conf" "$PGDATA"
        fi

        bashio::log.info "Upgrade completed successfully."
        RESTART_NEEDED=true

    else
        bashio::log.info "PostgreSQL data directory version ($CLUSTER_VERSION) matches image version ($IMAGE_VERSION)."
    fi
}

# ------------------ Start PostgreSQL server -------------------

start_postgres() {
    bashio::log.info "Starting PostgreSQL..."
    if [ "$(bashio::info.arch)" = "armv7" ]; then
        bashio::log.warning "ARMv7 detected: Starting without vectors.so"
        /usr/local/bin/immich-docker-entrypoint.sh postgres & true
        exit 0
    else
        /usr/local/bin/immich-docker-entrypoint.sh postgres -c config_file=/etc/postgresql/postgresql.conf & true
    fi
}

# ------------------- Main start/upgrade flow ------------------

# 1. Always check/upgrade the cluster BEFORE starting the server!
bashio::log.info "Checking for required PostgreSQL cluster upgrade before server start..."
upgrade_postgres_if_needed

# 2. Only now is it safe to start Postgres with current data dir
start_postgres

bashio::log.info "Waiting for PostgreSQL to start..."

(
# ------------------ Wait for Postgres server ready --------------

wait_for_postgres() {
    local tries=0
    while ! pg_isready -h "$DB_HOSTNAME" -p "$DB_PORT" -U "$DB_USERNAME" >/dev/null 2>&1; do
        tries=$((tries+1))
        if [ "$tries" -ge 60 ]; then
            bashio::log.error "Postgres did not start after 2 minutes, aborting."
            exit 1
        fi
        echo "PostgreSQL is starting up... ($tries/60)"
        sleep 2
    done
}

DB_PORT=5432
DB_HOSTNAME=localhost
DB_PASSWORD="$(bashio::config 'POSTGRES_PASSWORD')"
DB_PASSWORD="$(jq -rn --arg x "$DB_PASSWORD" '$x|@uri')"
DB_USERNAME=postgres
if bashio::config.has_value "POSTGRES_USER"; then
    DB_USERNAME="$(bashio::config "POSTGRES_USER")"
fi
export DB_PORT DB_HOSTNAME DB_USERNAME DB_PASSWORD

wait_for_postgres

# ------------------ Immich restart logic (if flagged) ---------------

restart_immich_addons_if_flagged() {
    if [ -f "$RESTART_FLAG_FILE" ]; then
        bashio::log.warning "Detected pending Immich add-on restart flag. Restarting all running Immich add-ons..."
        local addons slug found=0
        addons=$(curl -s -H "Authorization: Bearer $SUPERVISOR_TOKEN" http://supervisor/addons)
        if command -v jq >/dev/null; then
            for slug in $(echo "$addons" | jq -r '.data.addons[] | select(.state=="started") | .slug'); do
                if [[ "$slug" == *immich* ]]; then
                    bashio::log.info "Restarting addon $slug"
                    curl -s -X POST -H "Authorization: Bearer $SUPERVISOR_TOKEN" "http://supervisor/addons/$slug/restart"
                    found=1
                fi
            done
        else
            for slug in $(echo "$addons" | grep -o '"slug":"[^"]*"' | cut -d: -f2 | tr -d '"'); do
                if [[ "$slug" == *immich* ]]; then
                    bashio::log.info "Restarting addon $slug"
                    curl -s -X POST -H "Authorization: Bearer $SUPERVISOR_TOKEN" "http://supervisor/addons/$slug/restart"
                    found=1
                fi
            done
        fi
        if [ "$found" -eq 0 ]; then
            bashio::log.info "No Immich-related addon found running."
        fi
        rm -f "$RESTART_FLAG_FILE"
    fi
}

restart_immich_addons_if_flagged

# ----------- Postgres/extension version and upgrade logic ------------

get_available_extension_version() {
    local extname="$1"
    psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT/postgres" -v ON_ERROR_STOP=1 -tAc \
        "SELECT default_version FROM pg_available_extensions WHERE name = '$extname';" 2>/dev/null | xargs
}

is_extension_available() {
    local extname="$1"
    local result
    result=$(psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT/postgres" -v ON_ERROR_STOP=1 -tAc \
        "SELECT 1 FROM pg_available_extensions WHERE name = '$extname';" 2>/dev/null | xargs)
    [[ "$result" == "1" ]]
}

get_user_databases() {
    psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT/postgres" -v ON_ERROR_STOP=1 -tAc \
        "SELECT datname FROM pg_database WHERE datistemplate = false AND datallowconn = true;"
}

get_installed_extension_version() {
    local extname="$1"
    local dbname="$2"
    psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT/$dbname" -v ON_ERROR_STOP=1 -tAc \
        "SELECT extversion FROM pg_extension WHERE extname = '$extname';" 2>/dev/null | xargs
}

compare_versions() {
    local v1="$1"
    local v2="$2"
    if [ "$v1" = "$v2" ]; then return 1; fi
    if [ "$(printf '%s\n' "$v1" "$v2" | sort -V | head -n1)" = "$v1" ]; then
        return 0
    fi
    return 1
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
                if psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT/$db" -v ON_ERROR_STOP=1 -c "ALTER EXTENSION $extname UPDATE;"; then
                    RESTART_NEEDED=true
                else
                    bashio::log.error "Failed to upgrade $extname in $db. Aborting startup."
                    exit 1
                fi
            else
                bashio::log.info "$extname in $db already at latest version ($installed_version)"
            fi
        fi
    done
}

upgrade_extension_if_needed "vectors"
upgrade_extension_if_needed "vchord"

show_db_extensions

if [ "$RESTART_NEEDED" = true ]; then
    bashio::log.warning "A critical update (Postgres or extension) occurred. Will trigger Immich add-on restart after DB comes back up."
    touch "$RESTART_FLAG_FILE"
    bashio::addon.restart
    exit 0
fi

bashio::log.info "All initialization/version check steps completed successfully!"

if [ -d /config/backups ]; then
    echo "Cleaning /config/backups now that upgrade is done"
    rm -r /config/backups
fi

) & true
