#!/usr/bin/env bashio
# shellcheck shell=bash
# shellcheck disable=SC2155
set -e

bashio::log.warning "Warning - minimum configuration recommended : 2 cpu cores and 4 GB of memory. Otherwise the system will become unresponsive and crash."

unlock_sqlite_migrations() {
    local db_path="$1"

    if ! command -v sqlite3 >/dev/null 2>&1; then
        bashio::log.warning "sqlite3 not available; skipping SQLite migration lock check."
        return
    fi

    local is_locked
    is_locked=$(sqlite3 "$db_path" "SELECT is_locked FROM knex_migrations_lock WHERE \"index\" = 1;" 2>/dev/null || true)

    sqlite3 "$db_path" "CREATE TABLE IF NOT EXISTS knex_migrations_lock (\"index\" integer PRIMARY KEY, is_locked integer); \
        INSERT OR IGNORE INTO knex_migrations_lock (\"index\", is_locked) VALUES (1, 0); \
        UPDATE knex_migrations_lock SET is_locked = 0 WHERE \"index\" = 1;" \
        || bashio::log.warning "Failed to ensure SQLite migration lock table."

    if [[ "$is_locked" == "1" ]]; then
        bashio::log.warning "Locked SQLite migration table detected, attempting to unlock."
    fi
}

unlock_postgres_migrations() {
    if ! command -v psql >/dev/null 2>&1; then
        bashio::log.warning "psql not available; skipping PostgreSQL migration lock check."
        return
    fi

    if [[ -z "${POSTGRES_DATABASE:-}" || -z "${POSTGRES_USER:-}" || -z "${POSTGRES_HOST:-}" ]]; then
        bashio::log.warning "PostgreSQL configuration incomplete; skipping migration lock check."
        return
    fi

    local pg_port="${POSTGRES_PORT:-5432}"
    export PGPASSWORD="${POSTGRES_PASSWORD:-}"

    local is_locked
    is_locked=$(psql -h "$POSTGRES_HOST" -p "$pg_port" -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" -Atqc "SELECT is_locked FROM knex_migrations_lock WHERE index = 1;" 2>/dev/null || true)

    psql -h "$POSTGRES_HOST" -p "$pg_port" -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" -Atqc \
        "CREATE TABLE IF NOT EXISTS knex_migrations_lock (index integer PRIMARY KEY, is_locked integer); \
        INSERT INTO knex_migrations_lock (index, is_locked) VALUES (1, 0) ON CONFLICT (index) DO NOTHING; \
        UPDATE knex_migrations_lock SET is_locked = 0 WHERE index = 1;" \
        || bashio::log.warning "Failed to ensure PostgreSQL migration lock table."

    if [[ "$is_locked" == "1" ]]; then
        bashio::log.warning "Locked PostgreSQL migration table detected, attempting to unlock."
    fi

    unset PGPASSWORD
}

# Check data location
LOCATION=$(bashio::config 'data_location')
if [[ "$LOCATION" = "null" || -z "$LOCATION" ]]; then
    # Default location
    LOCATION="/config/addons_config/joplin"
else
    bashio::log.warning "Warning : a custom data location was selected, but the previous folder will NOT be copied. You need to do it manually"
fi

# Create folder
if [ ! -d "$LOCATION" ]; then
    echo "Creating $LOCATION"
    mkdir -p "$LOCATION"
fi

touch "$LOCATION"/database.sqlite

if [ ! -d "$LOCATION"/resources ]; then
    mkdir -p "$LOCATION"/resources
fi
ln -s "$LOCATION"/resources /home/joplin/packages/server

chown -R joplin:joplin "$LOCATION"
chmod -R 777 "$LOCATION"
chmod 755 "$LOCATION/database.sqlite"
export SQLITE_DATABASE="$LOCATION/database.sqlite"

if bashio::config.has_value 'POSTGRES_DATABASE'; then
    bashio::log.info "Using postgres"

    bashio::config.has_value 'DB_CLIENT' && export DB_CLIENT=$(bashio::config 'DB_CLIENT') && bashio::log.info 'Database client set'
    bashio::config.has_value 'POSTGRES_PASSWORD' && export POSTGRES_PASSWORD=$(bashio::config 'POSTGRES_PASSWORD') && bashio::log.info 'Postgrep Password set'
    bashio::config.has_value 'POSTGRES_DATABASE' && export POSTGRES_DATABASE=$(bashio::config 'POSTGRES_DATABASE') && bashio::log.info 'Postgrep Database set'
    bashio::config.has_value 'POSTGRES_USER' && export POSTGRES_USER=$(bashio::config 'POSTGRES_USER') && bashio::log.info 'Postgrep User set'
    bashio::config.has_value 'POSTGRES_PORT' && export POSTGRES_PORT=$(bashio::config 'POSTGRES_PORT') && bashio::log.info 'Postgrep Port set'
    bashio::config.has_value 'POSTGRES_HOST' && export POSTGRES_HOST=$(bashio::config 'POSTGRES_HOST') && bashio::log.info 'Postgrep Host set'
    unlock_postgres_migrations
else

    bashio::log.info "Using sqlite"
    unlock_sqlite_migrations "$SQLITE_DATABASE"

fi

##############
# LAUNCH APP #
##############

# Configure app
bashio::config.has_value 'MAILER_HOST' && export MAILER_HOST=$(bashio::config 'MAILER_HOST') && bashio::log.info 'Mailer Host set'
bashio::config.has_value 'MAILER_PORT' && export MAILER_PORT=$(bashio::config 'MAILER_PORT') && bashio::log.info 'Mailer Port set'
bashio::config.has_value 'MAILER_SECURITY' && export MAILER_SECURITY=$(bashio::config 'MAILER_SECURITY') && bashio::log.info 'Mailer Security set'
bashio::config.has_value 'MAILER_AUTH_USER' && export MAILER_AUTH_USER=$(bashio::config 'MAILER_AUTH_USER') && bashio::log.info 'Mailer User set'
bashio::config.has_value 'MAILER_AUTH_PASSWORD' && export MAILER_AUTH_PASSWORD=$(bashio::config 'MAILER_AUTH_PASSWORD') && bashio::log.info 'Mailer Password set'
bashio::config.has_value 'MAILER_NOREPLY_NAME' && export MAILER_NOREPLY_NAME=$(bashio::config 'MAILER_NOREPLY_NAME') && bashio::log.info 'Mailer Noreply Name set'
bashio::config.has_value 'MAILER_NOREPLY_EMAIL' && export MAILER_NOREPLY_EMAIL=$(bashio::config 'MAILER_NOREPLY_EMAIL') && bashio::log.info 'Mailer Noreply Email set'
bashio::config.has_value 'MAILER_ENABLED' && export MAILER_ENABLED=$(bashio::config 'MAILER_ENABLED') && bashio::log.info 'Mailer Enabled set'
export APP_BASE_URL=$(bashio::config 'APP_BASE_URL')
export ALLOWED_HOSTS="*"

bashio::log.info 'Starting Joplin. Initial user is "admin@localhost" with password "admin"'

cd /home/joplin || true
npm --prefix packages/server start
