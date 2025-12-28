#!/command/with-contenv bashio
# shellcheck shell=bash
set -euo pipefail

bashio::log.warning "Warning - minimum configuration recommended : 2 cpu cores and 4 GB of memory. Otherwise the system will become unresponsive and crash."

unlock_sqlite_migrations() {
    local db_path="$1"

    if ! command -v sqlite3 >/dev/null 2>&1; then
        bashio::log.warning "sqlite3 not available; skipping SQLite migration lock check."
        return 0
    fi

    # Only proceed if the DB file exists
    if [[ ! -f "$db_path" ]]; then
        bashio::log.warning "SQLite DB not found at $db_path; skipping migration unlock."
        return 0
    fi

    # If the lock table doesn't exist yet, nothing to unlock
    local has_table
    has_table="$(sqlite3 "$db_path" "SELECT 1 FROM sqlite_master WHERE type='table' AND name='knex_migrations_lock' LIMIT 1;" 2>/dev/null || true)"
    [[ "$has_table" == "1" ]] || return 0

    # Ensure the lock row exists (Knex expects one row)
    # Typical schema: (index INTEGER PRIMARY KEY, is_locked INTEGER)
    sqlite3 "$db_path" "
        PRAGMA busy_timeout=5000;
        INSERT OR IGNORE INTO knex_migrations_lock(\"index\", is_locked) VALUES (1, 0);
    " >/dev/null 2>&1 || true

    local is_locked
    is_locked="$(sqlite3 "$db_path" "PRAGMA busy_timeout=5000; SELECT is_locked FROM knex_migrations_lock WHERE \"index\"=1 LIMIT 1;" 2>/dev/null || true)"

    if [[ "$is_locked" == "1" ]]; then
        bashio::log.warning "Locked SQLite migration table detected, attempting to unlock."
        sqlite3 "$db_path" "
            PRAGMA busy_timeout=5000;
            UPDATE knex_migrations_lock SET is_locked = 0 WHERE \"index\"=1 AND is_locked=1;
        " >/dev/null 2>&1 || bashio::log.warning "Failed to clear SQLite migration lock."
    fi
}

repair_notifications_migration_sqlite() {
    local db_path="$1"

    if ! command -v sqlite3 >/dev/null 2>&1; then
        return 0
    fi

    if [[ ! -f "$db_path" ]]; then
        return 0
    fi

    local has_notifications
    has_notifications="$(sqlite3 "$db_path" "SELECT 1 FROM sqlite_master WHERE type='table' AND name='notifications' LIMIT 1;" 2>/dev/null || true)"
    [[ "$has_notifications" == "1" ]] || return 0

    local has_migrations
    has_migrations="$(sqlite3 "$db_path" "SELECT 1 FROM sqlite_master WHERE type='table' AND name='knex_migrations' LIMIT 1;" 2>/dev/null || true)"
    [[ "$has_migrations" == "1" ]] || return 0

    local has_entry
    has_entry="$(sqlite3 "$db_path" "SELECT 1 FROM knex_migrations WHERE name='20203012152842_notifications.js' LIMIT 1;" 2>/dev/null || true)"
    [[ "$has_entry" == "1" ]] && return 0

    bashio::log.warning "Notifications table exists but migration is missing; repairing knex_migrations entry."
    sqlite3 "$db_path" "
        PRAGMA busy_timeout=5000;
        INSERT INTO knex_migrations(name, batch, migration_time)
        VALUES ('20203012152842_notifications.js',
            COALESCE((SELECT MAX(batch) FROM knex_migrations), 1),
            CAST(strftime('%s','now') AS INTEGER) * 1000
        );
    " >/dev/null 2>&1 || bashio::log.warning "Failed to repair notifications migration entry."
}

unlock_postgres_migrations() {
    if ! command -v psql >/dev/null 2>&1; then
        bashio::log.warning "psql not available; skipping PostgreSQL migration lock check."
        return 0
    fi

    if [[ -z "${POSTGRES_DATABASE:-}" || -z "${POSTGRES_USER:-}" || -z "${POSTGRES_HOST:-}" ]]; then
        bashio::log.warning "PostgreSQL configuration incomplete; skipping migration lock check."
        return 0
    fi

    local pg_port="${POSTGRES_PORT:-5432}"
    export PGPASSWORD="${POSTGRES_PASSWORD:-}"

    # If table doesn't exist, skip
    local has_table
    has_table="$(psql -h "$POSTGRES_HOST" -p "$pg_port" -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" -Atqc \
        "SELECT 1 FROM information_schema.tables WHERE table_name='knex_migrations_lock' LIMIT 1;" 2>/dev/null || true)"
    [[ "$has_table" == "1" ]] || { unset PGPASSWORD; return 0; }

    # Ensure row exists
    psql -h "$POSTGRES_HOST" -p "$pg_port" -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" -Atqc \
        "INSERT INTO knex_migrations_lock(\"index\", is_locked) VALUES (1, 0) ON CONFLICT (\"index\") DO NOTHING;" \
        >/dev/null 2>&1 || true

    local is_locked
    is_locked="$(psql -h "$POSTGRES_HOST" -p "$pg_port" -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" -Atqc \
        "SELECT is_locked FROM knex_migrations_lock WHERE \"index\"=1 LIMIT 1;" 2>/dev/null || true)"

    if [[ "$is_locked" == "1" ]]; then
        bashio::log.warning "Locked PostgreSQL migration table detected, attempting to unlock."
        psql -h "$POSTGRES_HOST" -p "$pg_port" -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" -Atqc \
            "UPDATE knex_migrations_lock SET is_locked = 0 WHERE \"index\"=1 AND is_locked=1;" \
            >/dev/null 2>&1 || bashio::log.warning "Failed to clear PostgreSQL migration lock."
    fi

    unset PGPASSWORD
}

repair_notifications_migration_postgres() {
    if ! command -v psql >/dev/null 2>&1; then
        return 0
    fi

    if [[ -z "${POSTGRES_DATABASE:-}" || -z "${POSTGRES_USER:-}" || -z "${POSTGRES_HOST:-}" ]]; then
        return 0
    fi

    local pg_port="${POSTGRES_PORT:-5432}"
    export PGPASSWORD="${POSTGRES_PASSWORD:-}"

    local has_notifications
    has_notifications="$(psql -h "$POSTGRES_HOST" -p "$pg_port" -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" -Atqc \
        "SELECT 1 FROM information_schema.tables WHERE table_name='notifications' LIMIT 1;" 2>/dev/null || true)"
    [[ "$has_notifications" == "1" ]] || { unset PGPASSWORD; return 0; }

    local has_migrations
    has_migrations="$(psql -h "$POSTGRES_HOST" -p "$pg_port" -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" -Atqc \
        "SELECT 1 FROM information_schema.tables WHERE table_name='knex_migrations' LIMIT 1;" 2>/dev/null || true)"
    [[ "$has_migrations" == "1" ]] || { unset PGPASSWORD; return 0; }

    local has_entry
    has_entry="$(psql -h "$POSTGRES_HOST" -p "$pg_port" -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" -Atqc \
        "SELECT 1 FROM knex_migrations WHERE name='20203012152842_notifications.js' LIMIT 1;" 2>/dev/null || true)"
    [[ "$has_entry" == "1" ]] && { unset PGPASSWORD; return 0; }

    bashio::log.warning "Notifications table exists but migration is missing; repairing knex_migrations entry."
    psql -h "$POSTGRES_HOST" -p "$pg_port" -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" -Atqc \
        "INSERT INTO knex_migrations(name, batch, migration_time)
         SELECT '20203012152842_notifications.js',
                COALESCE(MAX(batch), 1),
                (EXTRACT(EPOCH FROM NOW()) * 1000)::bigint
         FROM knex_migrations
         WHERE NOT EXISTS (
             SELECT 1 FROM knex_migrations WHERE name='20203012152842_notifications.js'
         );" >/dev/null 2>&1 || bashio::log.warning "Failed to repair notifications migration entry."

    unset PGPASSWORD
}

# -------------------
# Data location
# -------------------
LOCATION="$(bashio::config 'data_location')"
if [[ "$LOCATION" == "null" || -z "$LOCATION" ]]; then
    LOCATION="/config/addons_config/joplin"
else
    bashio::log.warning "Warning : a custom data location was selected, but the previous folder will NOT be copied. You need to do it manually"
fi

install -d -m 0755 -o joplin -g joplin "$LOCATION" "$LOCATION/resources"

# Ensure DB exists (touch does not truncate)
if [[ ! -f "$LOCATION/database.sqlite" ]]; then
    install -m 0644 -o joplin -g joplin /dev/null "$LOCATION/database.sqlite"
fi

# Link resources into server dir
ln -sfn "$LOCATION/resources" /home/joplin/packages/server/resources

export SQLITE_DATABASE="$LOCATION/database.sqlite"

# -------------------
# DB selection + unlock
# -------------------
if bashio::config.has_value 'POSTGRES_DATABASE'; then
    bashio::log.info "Using postgres"

    bashio::config.has_value 'DB_CLIENT' && export DB_CLIENT="$(bashio::config 'DB_CLIENT')"
    bashio::config.has_value 'POSTGRES_PASSWORD' && export POSTGRES_PASSWORD="$(bashio::config 'POSTGRES_PASSWORD')"
    bashio::config.has_value 'POSTGRES_DATABASE' && export POSTGRES_DATABASE="$(bashio::config 'POSTGRES_DATABASE')"
    bashio::config.has_value 'POSTGRES_USER' && export POSTGRES_USER="$(bashio::config 'POSTGRES_USER')"
    bashio::config.has_value 'POSTGRES_PORT' && export POSTGRES_PORT="$(bashio::config 'POSTGRES_PORT')"
    bashio::config.has_value 'POSTGRES_HOST' && export POSTGRES_HOST="$(bashio::config 'POSTGRES_HOST')"

    unlock_postgres_migrations
    repair_notifications_migration_postgres
else
    bashio::log.info "Using sqlite"
    unlock_sqlite_migrations "$SQLITE_DATABASE"
    repair_notifications_migration_sqlite "$SQLITE_DATABASE"
fi

# -------------------
# App env
# -------------------
bashio::config.has_value 'MAILER_HOST' && export MAILER_HOST="$(bashio::config 'MAILER_HOST')"
bashio::config.has_value 'MAILER_PORT' && export MAILER_PORT="$(bashio::config 'MAILER_PORT')"
bashio::config.has_value 'MAILER_SECURITY' && export MAILER_SECURITY="$(bashio::config 'MAILER_SECURITY')"
bashio::config.has_value 'MAILER_AUTH_USER' && export MAILER_AUTH_USER="$(bashio::config 'MAILER_AUTH_USER')"
bashio::config.has_value 'MAILER_AUTH_PASSWORD' && export MAILER_AUTH_PASSWORD="$(bashio::config 'MAILER_AUTH_PASSWORD')"
bashio::config.has_value 'MAILER_NOREPLY_NAME' && export MAILER_NOREPLY_NAME="$(bashio::config 'MAILER_NOREPLY_NAME')"
bashio::config.has_value 'MAILER_NOREPLY_EMAIL' && export MAILER_NOREPLY_EMAIL="$(bashio::config 'MAILER_NOREPLY_EMAIL')"
bashio::config.has_value 'MAILER_ENABLED' && export MAILER_ENABLED="$(bashio::config 'MAILER_ENABLED')"

export APP_BASE_URL="$(bashio::config 'APP_BASE_URL')"
export ALLOWED_HOSTS="*"

bashio::log.info 'Starting Joplin. Initial user is "admin@localhost" with password "admin"'

cd /home/joplin || exit 1
exec npm --prefix packages/server start
