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

# Define current PostgreSQL major version
PG_MAJOR_VERSION="${PG_MAJOR:-15}"

# Setup data directory
mkdir -p "$PGDATA"
chown -R postgres:postgres "$PGDATA"
chmod 700 "$PGDATA"

# Set permissions
chmod -R 755 "$CONFIG_HOME"

# Ensure PostgreSQL config file exists
if [ ! -f "$CONFIG_HOME/postgresql.conf" ]; then
    if [ -f /usr/local/share/postgresql/postgresql.conf.sample ]; then
        cp /usr/local/share/postgresql/postgresql.conf.sample "$CONFIG_HOME/postgresql.conf"
    elif [ -f /usr/share/postgresql/postgresql.conf.sample ]; then
        cp /usr/share/postgresql/postgresql.conf.sample "$CONFIG_HOME/postgresql.conf"
    else
        bashio::exit.nok "Config file not found, please ask maintainer"
        exit 1
    fi
    bashio::log.warning "A default postgresql.conf file was copied to $CONFIG_HOME. Please customize it and restart the add-on."
else
    bashio::log.info "Using existing postgresql.conf file in $CONFIG_HOME."
fi

###############################
# Launch PostgreSQL           #
###############################

cd /config || true

bashio::log.info "Starting PostgreSQL..."

if [ "$(bashio::info.arch)" = "armv7" ]; then
    bashio::log.warning "ARMv7 detected: Starting without vectors.so"
    docker-entrypoint.sh postgres & true
    exit 0
else
    docker-entrypoint.sh postgres -c shared_preload_libraries=vectors.so -c search_path="public, vectors" & true
fi

###############################
# Wait for PostgreSQL Startup #
###############################

bashio::log.info "Waiting for PostgreSQL to start..."

# Set PostgreSQL connection variables
DB_PORT=5432
DB_HOSTNAME=localhost
DB_PASSWORD="$(bashio::config 'POSTGRES_PASSWORD')"
DB_USERNAME=postgres
if bashio::config.has_value "POSTGRES_USER"; then
    DB_USERNAME="$(bashio::config "POSTGRES_USER")"
fi
export DB_PORT DB_HOSTNAME DB_USERNAME DB_PASSWORD

( bashio::net.wait_for 5432 localhost 900

until pg_isready -h "$DB_HOSTNAME" -p "$DB_PORT" -U "$DB_USERNAME" >/dev/null 2>&1; do
    echo "PostgreSQL is starting up..."
    sleep 2
done

###############################
# PostgreSQL Major Version Upgrade #
###############################

update_postgres() {

# Read the previous PostgreSQL version from file
OLD_PG_VERSION=$(cat "$PG_VERSION_FILE" 2>/dev/null || echo "$PG_MAJOR_VERSION")

if [ "$OLD_PG_VERSION" != "$PG_MAJOR_VERSION" ]; then
    bashio::log.warning "PostgreSQL major version changed ($OLD_PG_VERSION → $PG_MAJOR_VERSION). Running upgrade..."

    OLD_BIN_DIR="/usr/lib/postgresql/$OLD_PG_VERSION/bin"
    NEW_BIN_DIR="/usr/lib/postgresql/$PG_MAJOR_VERSION/bin"

    # Check if the old PostgreSQL binaries exist
    if [ ! -d "$OLD_BIN_DIR" ]; then
        bashio::log.warning "Old PostgreSQL binaries ($OLD_PG_VERSION) not found! Downloading..."

        # Determine the package URL (adjust this as needed for your PostgreSQL distribution)
        PG_DOWNLOAD_URL="https://ftp.postgresql.org/pub/source/v$OLD_PG_VERSION/postgresql-$OLD_PG_VERSION.tar.gz"

        # Create a temporary directory for the download
        TMP_DIR=$(mktemp -d)
        cd "$TMP_DIR" || exit 1

        # Download and extract PostgreSQL source
        wget "$PG_DOWNLOAD_URL" -O postgresql.tar.gz
        tar -xzf postgresql.tar.gz

        # Build only the necessary binaries
        cd "postgresql-$OLD_PG_VERSION" || exit 1
        ./configure --prefix="$OLD_BIN_DIR"
        make -j$(nproc)
        make install

        # Clean up
        cd /config || exit 1
        rm -rf "$TMP_DIR"
    fi

    # Run pg_upgrade with the correct paths
    pg_upgrade --old-datadir="$PGDATA" \
               --new-datadir="$PGDATA-new" \
               --old-bindir="$OLD_BIN_DIR" \
               --new-bindir="$NEW_BIN_DIR"

    # Replace old data directory with upgraded one
    mv "$PGDATA" "$PGDATA-old"
    mv "$PGDATA-new" "$PGDATA"
    rm -rf "$PGDATA-old"

    # Store the new PostgreSQL version
    echo "$PG_MAJOR_VERSION" > "$PG_VERSION_FILE"
fi
}

#####################################
# Enable & Upgrade pgvector.rs      #
#####################################

# Function: Check if 'vectors' extension is enabled
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

# Function: Enable (or re-create) 'vectors' extension
enable_vector_extension() {
    bashio::log.info "Enabling 'vectors' extension..."
    psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT" -c "DROP EXTENSION IF EXISTS vectors; CREATE EXTENSION vectors;" >/dev/null 2>&1
    psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT" -c "ALTER EXTENSION vectors UPDATE; SELECT pgvectors_upgrade();" >/dev/null 2>&1
}

# Function: Store the current pgvector.rs version in a file
store_vector_version() {
    local version
    version=$(psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT" \
               -tAc "SELECT extversion FROM pg_extension WHERE extname = 'vectors';")
    echo "$version" > "$VECTOR_VERSION_FILE"
}

# Function: Detect previous and new pgvector.rs versions, and upgrade if needed
upgrade_vector_extension() {
    local current_version desired_version
    current_version=$(cat "$VECTOR_VERSION_FILE" 2>/dev/null || echo "unknown")
    desired_version=$(psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT" \
                    -tAc "SELECT extversion FROM pg_extension WHERE extname = 'vectors';")

    if [[ "$current_version" != "$desired_version" ]]; then
        bashio::log.warning "Upgrading 'vectors' extension from version $current_version → $desired_version..."
        psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT" -c "ALTER EXTENSION vectors UPDATE;" >/dev/null 2>&1

        # Cleanup outdated indexes
        bashio::log.info "Cleaning up outdated vector indexes..."
        psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT" \
            -c "DROP INDEX IF EXISTS clip_index;" >/dev/null 2>&1

        # Store new pgvector version
        echo "$desired_version" > "$VECTOR_VERSION_FILE"
    else
        bashio::log.info "'vectors' extension is already at the latest version ($desired_version)."
    fi
}

# Function: Troubleshoot vector extension
troubleshoot_vector_extension() {
    bashio::log.error "Troubleshooting pgvector.rs installation..."

    if ! pg_isready -h "$DB_HOSTNAME" -p "$DB_PORT" -U "$DB_USERNAME" >/dev/null 2>&1; then
        bashio::log.error "PostgreSQL is not running or unreachable."
        exit 1
    fi

    local ext_check
    ext_check=$(psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT" \
                -tAc "SELECT count(*) FROM pg_available_extensions WHERE name = 'vectors';")
    if [[ "$ext_check" -eq 0 ]]; then
        bashio::log.error "'vectors' extension is missing. Ensure pgvector.rs is installed."
        exit 1
    fi
}

###################################
# Main Extension Handling         #
###################################

# Store previous vector version
update_postgres

if ! check_vector_extension; then
    enable_vector_extension
fi

# Store previous vector version
store_vector_version

# Upgrade vector extension if needed
upgrade_vector_extension

# Final verification
check_vector_extension || troubleshoot_vector_extension

bashio::log.info "All initialization steps completed successfully!" ) & true
