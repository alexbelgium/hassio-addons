#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

###############################
# Configuration & Setup       #
###############################

CONFIG_HOME="/config"
PGDATA="${PGDATA:-/config/database}"
PG_VERSION_FILE="$PGDATA/pg_major_version"
VCHORD_VERSION_FILE="$PGDATA/vchord_version"

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
    bashio::log.warning "ARMv7 detected: Starting without extensions"
    immich-docker-entrypoint.sh postgres & true
    exit 0
else
    immich-docker-entrypoint.sh postgres "-c config_file=/etc/postgresql/postgresql.conf" & true
fi

###############################
# Wait for PostgreSQL Startup #
###############################

bashio::log.info "Waiting for PostgreSQL to start..."

( bashio::net.wait_for 5432 localhost 900

# Set PostgreSQL connection variables
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

###############################
# PostgreSQL Major Version Upgrade #
###############################

update_postgres() {
    # Read the previous PostgreSQL version from file
    OLD_PG_VERSION=$(cat "$PG_VERSION_FILE" 2>/dev/null || echo "$PG_MAJOR_VERSION")

    if [ "$OLD_PG_VERSION" != "$PG_MAJOR_VERSION" ]; then
        bashio::log.warning "PostgreSQL major version changed ($OLD_PG_VERSION → $PG_MAJOR_VERSION). Running upgrade..."

        # Set environment variables for the upgrade script
        export DATA_DIR="$PGDATA"
        export BINARIES_DIR="/usr/lib/postgresql/$PG_MAJOR_VERSION/bin"
        export BACKUP_DIR="/config/backups"
        export PSQL_VERSION="$PG_MAJOR_VERSION"

        # Install binaries
        apt-get update &>/dev/null
        install -y procps rsync postgresql-"$PG_MAJOR_VERSION" postgresql-"$OLD_PG_VERSION" &>/dev/null

        # Download and run the upgrade script
        TMP_SCRIPT=$(mktemp)
        wget https://raw.githubusercontent.com/linkyard/postgres-upgrade/refs/heads/main/upgrade-postgres.sh -O "$TMP_SCRIPT"
        chmod +x "$TMP_SCRIPT"
        "$TMP_SCRIPT"

        # Store the new PostgreSQL version if successful
        echo "$PG_MAJOR_VERSION" > "$PG_VERSION_FILE"
    fi
}

#####################################
# Enable & Upgrade vchord      #
#####################################

# Function: Check if 'vchord' extension is enabled
check_vchord_extension() {
    bashio::log.info "Checking if 'vchord' extension is enabled..."
    local result
    result=$(psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT" \
               -tAc "SELECT extname FROM pg_extension WHERE extname = 'vchord';")
    if [[ "$result" == "vchord" ]]; then
        bashio::log.info "'vchord' extension is enabled."
        return 0
    else
        bashio::log.error "'vchord' extension is NOT enabled."
        return 1
    fi
}

# Function: Enable (or re-create) 'vchord' extension
enable_vchord_extension() {
    bashio::log.info "Enabling 'vchord' extension..."
    psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT" -c "DROP EXTENSION IF EXISTS vchord;" >/dev/null 2>&1
    psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT" -c "CREATE EXTENSION vchord;" >/dev/null 2>&1
    psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT" -c "ALTER EXTENSION vchord UPDATE;" >/dev/null 2>&1
}

# Function: Store the current vchord version in a file
store_vchord_version() {
    local version
    version=$(psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT" \
               -tAc "SELECT extversion FROM pg_extension WHERE extname = 'vchord';")
    echo "$version" > "$VCHORD_VERSION_FILE"
}

# Function: Detect previous and new vchord versions, and upgrade if needed
upgrade_vchord_extension() {
    local current_version desired_version
    current_version=$(cat "$VCHORD_VERSION_FILE" 2>/dev/null || echo "unknown")
    desired_version=$(psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT" \
                    -tAc "SELECT extversion FROM pg_extension WHERE extname = 'vchord';")

    if [[ "$current_version" != "$desired_version" ]]; then
        bashio::log.warning "Upgrading 'vchord' extension from version $current_version → $desired_version..."
        psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME@$DB_PORT" -c "ALTER EXTENSION vchord UPDATE;" >/dev/null 2>&1

        # Cleanup outdated indexes if needed (customize this line as needed for your DB schema)
        bashio::log.info "Cleaning up outdated vector indexes (if any)..."
        psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT" \
            -c "DROP INDEX IF EXISTS clip_index;" >/dev/null 2>&1

        # Store new vchord version
        echo "$desired_version" > "$VCHORD_VERSION_FILE"
    else
        bashio::log.info "'vchord' extension is already at the latest version ($desired_version)."
    fi
}

# Function: Troubleshoot vchord extension
troubleshoot_vchord_extension() {
    bashio::log.error "Troubleshooting vchord installation..."

    if ! pg_isready -h "$DB_HOSTNAME" -p "$DB_PORT" -U "$DB_USERNAME" >/dev/null 2>&1; then
        bashio::log.error "PostgreSQL is not running or unreachable."
        exit 1
    fi

    local ext_check
    ext_check=$(psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT" \
                -tAc "SELECT count(*) FROM pg_available_extensions WHERE name = 'vchord';")
    if [[ "$ext_check" -eq 0 ]]; then
        bashio::log.error "'vchord' extension is missing. Ensure vchord is installed. If this is your first boot it will be installed later"
        exit 1
    fi
}

###################################
# Main Extension Handling         #
###################################

# Store previous vchord version
update_postgres

if ! check_vchord_extension; then
    enable_vchord_extension
fi

# Store previous vchord version
store_vchord_version

# Upgrade vchord extension if needed
upgrade_vchord_extension

# Final verification
check_vchord_extension || troubleshoot_vchord_extension

bashio::log.info "All initialization steps completed successfully!" ) & true
