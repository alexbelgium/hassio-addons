#!/usr/bin/env bashio
# shellcheck shell=bash
# shellcheck disable=SC2155,SC2016
set -e

# Function to export options from JSON to env variables
export_options() {
    local json_source="/data/options.json"
    bashio::log.info "Exporting addon options from ${json_source}"

    # Get all keys and export their raw values
    mapfile -t keys < <(jq -r 'keys[]' "${json_source}")
    for key in "${keys[@]}"; do
        local value
        value=$(jq -r ".${key}" "${json_source}")
        # Hide passwords
        if bashio::config.false "verbose" || [[ "$key" == *"PASS"* ]]; then
            bashio::log.blue "${key}=******"
        else
            bashio::log.blue "${key}='${value}'"
        fi
        # Export value
        export "${key}=${value}"
    done
}

# Function to check and adjust DB_HOSTNAME if necessary
check_db_hostname() {
    if [[ "$DB_HOSTNAME" == "homeassistant.local" ]]; then
        local host_ip
        host_ip=$(bashio::network.ipv4_address)
        host_ip=${host_ip%/*}
        export DB_HOSTNAME="$host_ip"
        bashio::log.warning "DB_HOSTNAME was set to homeassistant.local. Using detected IP: $DB_HOSTNAME"
    fi

    if ! ping -c 1 -W 3 "$DB_HOSTNAME" >/dev/null 2>&1; then
        bashio::log.warning "------------------------------------"
        bashio::log.warning "DB_HOSTNAME ($DB_HOSTNAME) is not reachable."
        bashio::log.warning "Please set it to the IP address of your database."
        bashio::log.warning "The addon will stop until this is fixed."
        bashio::log.warning "------------------------------------"
        sleep 30
        bashio::addon.stop
    else
        echo "$DB_HOSTNAME is reachable."
    fi
}

# Function to migrate internal database to external storage if needed
migrate_database() {
    if [ -f /share/postgresql_immich.tar.gz ]; then
        bashio::log.warning "Previous database export found at /share/postgresql_immich.tar.gz"
    elif [ -d /data/postgresql ]; then
        bashio::log.warning "Internal Postgres database detected. Migrating to /share/postgresql_immich.tar.gz"
        tar -zcvf /share/postgresql_immich.tar.gz /data/postgresql
        rm -rf /data/postgresql
    fi
}

# Function to validate required configuration values
validate_config() {
    local missing=false
    for var in DB_USERNAME DB_HOSTNAME DB_PASSWORD DB_DATABASE_NAME DB_PORT JWT_SECRET; do
        if ! bashio::config.has_value "${var}"; then
            bashio::log.error "Missing required configuration: ${var}"
            missing=true
        fi
    done
    if [ "$missing" = true ]; then
        bashio::exit.nok "Please ensure all required options are set."
    fi
}

# Function to export DB variables to s6 environment if applicable
export_db_env() {
    if [ -d /var/run/s6/container_environment ]; then
        for var in DB_USERNAME DB_PASSWORD DB_DATABASE_NAME DB_PORT DB_HOSTNAME JWT_SECRET; do
            printf "%s" "${!var}" > "/var/run/s6/container_environment/${var}"
        done
    fi
}

# Function to set up the root user with a secure password
setup_root_user() {
    # Generate DB_ROOT_PASSWORD if not set (12-character alphanumeric).
    if bashio::config.has_value "DB_ROOT_PASSWORD"; then
        export DB_ROOT_PASSWORD="$(bashio::config 'DB_ROOT_PASSWORD')"
    else
        bashio::log.warning "DB_ROOT_PASSWORD not set. Generating a random 12-character alphanumeric password and storing it in the addon options."
        export DB_ROOT_PASSWORD="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c12)"
        bashio::addon.option "DB_ROOT_PASSWORD" "${DB_ROOT_PASSWORD}"

        # Store generated password in the s6 environment if available
        if [ -d /var/run/s6/container_environment ]; then
            printf "%s" "${DB_ROOT_PASSWORD}" > "/var/run/s6/container_environment/DB_ROOT_PASSWORD"
        fi
    fi

    # 1. Try connecting as root with the known default password "securepassword"
    if PGPASSWORD="securepassword" psql -U root -h "${DB_HOSTNAME}" -p "${DB_PORT}" -d postgres -c '\q' 2>/dev/null; then
        # If successful, root has the default password; update it
        bashio::log.info "Detected root user with default password. Updating to new DB_ROOT_PASSWORD..."
        PGPASSWORD="securepassword" psql -U root -h "${DB_HOSTNAME}" -p "${DB_PORT}" -d postgres <<EOF
ALTER ROLE root WITH PASSWORD '${DB_ROOT_PASSWORD}';
EOF
    else
        # 2. If that fails, check if the root user exists at all
        if ! PGPASSWORD="${DB_PASSWORD}" \
             psql -U "${DB_USERNAME}" -h "${DB_HOSTNAME}" -p "${DB_PORT}" -d postgres -tAc \
             "SELECT 1 FROM pg_roles WHERE rolname='root'" | grep -q 1; then
            # 3. Create root user if it doesn't exist
            bashio::log.info "Root user does not exist. Creating root user with DB_ROOT_PASSWORD..."
            PGPASSWORD="${DB_PASSWORD}" psql -U "${DB_USERNAME}" -h "${DB_HOSTNAME}" -p "${DB_PORT}" -d postgres <<EOF
CREATE ROLE root WITH LOGIN SUPERUSER CREATEDB CREATEROLE PASSWORD '${DB_ROOT_PASSWORD}';
EOF
        else
            bashio::log.info "Root user exists with a non-default password. No migration needed."
        fi
    fi
}

# Function to set up the database
setup_database() {
    bashio::log.info "Setting up external PostgreSQL database..."

    # Create the database if it does not exist
    if ! PGPASSWORD="${DB_PASSWORD}" \
         psql -U "${DB_USERNAME}" -h "${DB_HOSTNAME}" -p "${DB_PORT}" -d postgres -tAc \
         "SELECT 1 FROM pg_database WHERE datname='${DB_DATABASE_NAME}';" | grep -q 1; then
        bashio::log.info "Database does not exist. Creating it now..."
        PGPASSWORD="${DB_PASSWORD}" psql -U "${DB_USERNAME}" -h "${DB_HOSTNAME}" -p "${DB_PORT}" -d postgres <<EOF
CREATE DATABASE ${DB_DATABASE_NAME};
EOF
    else
        bashio::log.info "Database ${DB_DATABASE_NAME} already exists. Ensuring it is configured correctly."
    fi

    # Ensure the user exists and update its password
    PGPASSWORD="${DB_PASSWORD}" psql -U "${DB_USERNAME}" -h "${DB_HOSTNAME}" -p "${DB_PORT}" -d postgres <<EOF
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${DB_USERNAME}') THEN
        CREATE USER ${DB_USERNAME} WITH ENCRYPTED PASSWORD '${DB_PASSWORD}';
    ELSE
        ALTER USER ${DB_USERNAME} WITH ENCRYPTED PASSWORD '${DB_PASSWORD}';
    END IF;
END
\$\$;
EOF

    # Ensure the user has full privileges on the database
    PGPASSWORD="${DB_PASSWORD}" psql -U "${DB_USERNAME}" -h "${DB_HOSTNAME}" -p "${DB_PORT}" -d postgres <<EOF
GRANT ALL PRIVILEGES ON DATABASE ${DB_DATABASE_NAME} TO ${DB_USERNAME};
EOF

    bashio::log.info "Database setup completed successfully."
}

# Function to check if vectors extension is enabled
check_vector_extension() {
    echo "Checking if 'vectors' extension is enabled..."
    RESULT=$(PGPASSWORD="${DB_PASSWORD}" \
        psql -U "$DB_USERNAME" -h "$DB_HOSTNAME" -p "$DB_PORT" -d "$DB_DATABASE_NAME" -tAc \
        "SELECT extname FROM pg_extension WHERE extname = 'vectors';")

    if [[ "$RESULT" == "vectors" ]]; then
        echo "✅ 'vectors' extension is enabled."
        exit 0
    else
        bashio::log.warning "❌ 'vectors' extension is NOT enabled."
        return 1
    fi
}

#########################
# Main script execution #
#########################

export_options
check_db_hostname
migrate_database
validate_config
export_db_env
setup_root_user
setup_database
check_vector_extension
