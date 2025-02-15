#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

###############################
# Configuration & Setup       #
###############################

CONFIG_HOME="/config"
PGDATA="${PGDATA:-/config/database}"
PG_VERSION_FILE="$PGDATA/pg_major_version"
VECTOR_VERSION_FILE="$PGDATA/pgvector_version"

# Define current versions
PG_MAJOR_VERSION="${PG_MAJOR:-15}"
if [ ! -f "$PG_VERSION_FILE" ]; then
    echo "$PG_MAJOR_VERSION" > "$PG_VERSION_FILE"
fi

# Create necessary directories
mkdir -p "$CONFIG_HOME"
if [ ! -f "$CONFIG_HOME/postgresql.conf" ]; then
    if [ -f /usr/local/share/postgresql/postgresql.conf.sample ]; then
        cp /usr/local/share/postgresql/postgresql.conf.sample "$CONFIG_HOME/postgresql.conf"
    elif [ -f /usr/share/postgresql/postgresql.conf.sample ]; then
        cp /usr/share/postgresql/postgresql.conf.sample "$CONFIG_HOME/postgresql.conf"
    else
        bashio::exit.nok "Config file not found, please ask maintainer"
        exit 1
    fi
    bashio::log.warning "A default config.env file was copied in $CONFIG_HOME. Please customize according to https://hub.docker.com/_/postgres and restart the add-on"
else
    bashio::log.warning "Using existing config.env file in $CONFIG_HOME."
fi

# Setup data directory
mkdir -p "$PGDATA"
chown -R postgres:postgres "$PGDATA"
chmod 700 "$PGDATA"

# Set permissions
chmod -R 755 "$CONFIG_HOME"

###############################
# Launch PostgreSQL           #
###############################

cd /config || true

bashio::log.info "Starting PostgreSQL..."

# Start background tasks
if [ "$(bashio::info.arch)" = "armv7" ]; then
    bashio::log.warning "ARMv7 detected: Starting without vectors.so"
    docker-entrypoint.sh postgres & true
    exit 0
else
    docker-entrypoint.sh postgres -c shared_preload_libraries=vectors.so -c search_path="public, vectors" & true
fi

# If not armv7
docker-entrypoint.sh postgres -c shared_preload_libraries=vectors.so -c search_path="public, vectors" & true

###############################
# Wait for PostgreSQL Startup #
###############################

( bashio::log.info "Waiting for PostgreSQL to start..."
bashio::net.wait_for 5432 localhost 900

###############################
# PostgreSQL Major Version Upgrade Check #
###############################

OLD_PG_VERSION=$(cat "$PG_VERSION_FILE")
if [ "$OLD_PG_VERSION" != "$PG_MAJOR_VERSION" ]; then
    bashio::log.warning "PostgreSQL major version changed ($OLD_PG_VERSION → $PG_MAJOR_VERSION). Running upgrade..."

    # Note: Ensure pg_upgrade is installed and the paths below match your environment.
    pg_upgrade --old-datadir="$PGDATA" \
               --new-datadir="$PGDATA-new" \
               --old-bindir="/usr/lib/postgresql/$OLD_PG_VERSION/bin" \
               --new-bindir="/usr/lib/postgresql/$PG_MAJOR_VERSION/bin"

    # Replace old data directory with upgraded one
    mv "$PGDATA" "$PGDATA-old"
    mv "$PGDATA-new" "$PGDATA"
    rm -rf "$PGDATA-old"

    # Update the version file
    echo "$PG_MAJOR_VERSION" > "$PG_VERSION_FILE"
fi

#####################################
# Enable & Upgrade pgvector.rs      #
#####################################

# Set connection variables for Postgres
DB_PORT=5432
DB_HOSTNAME=localhost
DB_PASSWORD="$(bashio::config 'POSTGRES_PASSWORD')"
DB_USERNAME=postgres
if bashio::config.has_value "POSTGRES_USER"; then
    DB_USERNAME="$(bashio::config "POSTGRES_USER")"
fi
export DB_PORT DB_HOSTNAME DB_USERNAME DB_PASSWORD

# Function: Check if the "vectors" extension is enabled
check_vector_extension() {
    bashio::log.info "Checking if 'vectors' extension is enabled..."
    local result
    result=$(psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT" \
               -tAc "SELECT extname FROM pg_extension WHERE extname = 'vectors';")
    if [[ "$result" == "vectors" ]]; then
        bashio::log.info "'vectors' extension is enabled."
        return 0
    else
        bashio::log.error "'vectors' extension is NOT enabled."
        return 1
    fi
}

# Function: Enable (or re-create) the "vectors" extension
enable_vector_extension() {
    bashio::log.info "Enabling 'vectors' extension..."
    cat <<EOF > /setup_postgres.sql
DROP EXTENSION IF EXISTS vectors;
CREATE EXTENSION vectors;
EOF
    psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT" < /setup_postgres.sql >/dev/null 2>&1
    rm /setup_postgres.sql || true
}

# Function: Store the current pgvector.rs extension version in a file
store_vector_version() {
    local version
    version=$(psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT" \
               -tAc "SELECT extversion FROM pg_extension WHERE extname = 'vectors';")
    echo "$version" > "$VECTOR_VERSION_FILE"
}

# Function: Cleanup outdated vector indexes (adjust as needed)
cleanup_vector_indexes() {
    bashio::log.info "Cleaning up outdated vector indexes..."
    psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT" \
         -c "DROP INDEX IF EXISTS clip_index;" >/dev/null 2>&1
}

# Function: Upgrade the "vectors" extension if a desired version is provided
upgrade_vector_extension() {
    local current_version desired_version
    current_version=$(psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT" \
                     -tAc "SELECT extversion FROM pg_extension WHERE extname = 'vectors';")
    # Use the desired version from config; if not set, use current version
    desired_version=$(bashio::config 'VECTOR_EXTENSION_VERSION' || echo "$current_version")

    if [[ "$current_version" != "$desired_version" ]]; then
        bashio::log.warning "Upgrading 'vectors' extension from version $current_version to $desired_version..."
        psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT" \
             -c "ALTER EXTENSION vectors UPDATE TO '$desired_version';" >/dev/null 2>&1
        cleanup_vector_indexes
        echo "$desired_version" > "$VECTOR_VERSION_FILE"
    else
        bashio::log.info "'vectors' extension is already at the desired version ($desired_version)."
    fi
}

# Function: Troubleshooting routine if extension checks fail
troubleshoot_vector_extension() {
    bashio::log.error "Troubleshooting pgvector.rs installation:"

    bashio::log.info "Checking if PostgreSQL is running..."
    if ! pg_isready -h "$DB_HOSTNAME" -p "$DB_PORT" -U "$DB_USERNAME" >/dev/null 2>&1; then
        bashio::log.error "PostgreSQL is not running or unreachable. Start the database and check network settings."
        exit 1
    else
        bashio::log.info "PostgreSQL is running."
    fi

    bashio::log.info "Verifying availability of the 'vectors' extension..."
    local ext_check
    ext_check=$(psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT" \
                -tAc "SELECT count(*) FROM pg_available_extensions WHERE name = 'vectors';")
    if [[ "$ext_check" -eq 0 ]]; then
        bashio::log.error "'vectors' extension is not available. Ensure that the pgvector.rs extension is installed."
        bashio::log.error "Try running: ALTER SYSTEM SET shared_preload_libraries = 'vectors'; then restart PostgreSQL."
        exit 1
    else
        bashio::log.info "'vectors' extension is available."
    fi
}

###################################
# Main Extension Handling         #
###################################

# If the extension isn’t enabled, create it.
if ! check_vector_extension; then
    enable_vector_extension
fi

# Store the initial pgvector.rs version
store_vector_version

# If a desired version is provided, attempt to upgrade.
upgrade_vector_extension

# Verify that the extension is enabled (and upgraded, if needed).
check_vector_extension || troubleshoot_vector_extension

echo "All initialization steps done" ) & true
