#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# INITALISATION #
#################

bashio::log.info "Creating folders"
mkdir -p "$STORAGE_FOLDER"

# Upstream Linkwarden (packages/filesystem/*.ts) resolves STORAGE_FOLDER via:
#   path.join(process.cwd(), '../..', STORAGE_FOLDER, filePath)
# The yarn workspace commands run from apps/web/ or apps/worker/, so
# process.cwd()/../.. resolves to the monorepo root /data_linkwarden.
# Node.js path.join treats absolute path segments as relative when they are not
# the first argument, so an absolute STORAGE_FOLDER like /config/library becomes
# /data_linkwarden/config/library instead of /config/library.
# This affects all filesystem operations: createFile, createFolder, readFile,
# moveFile, removeFile, removeFolder.
# Fix: symlink the top-level directory so all subpaths resolve correctly.
fix_linkwarden_path() {
    local actual_path="$1"
    local resolved_path="/data_linkwarden${actual_path}"

    # Only needed for absolute paths that differ after prefixing
    if [ "$resolved_path" = "$actual_path" ]; then
        return
    fi

    mkdir -p "$(dirname "$resolved_path")"

    # Preserve any data already written to the non-persistent path
    if [ -d "$resolved_path" ] && [ ! -L "$resolved_path" ]; then
        if ! cp -rn "$resolved_path/." "$actual_path/" 2>/dev/null; then
            bashio::log.warning "Could not copy existing data from $resolved_path to $actual_path"
        fi
        rm -rf "$resolved_path"
    fi

    ln -sfn "$actual_path" "$resolved_path"
    bashio::log.info "Symlinked $resolved_path -> $actual_path"
}

if [[ "$STORAGE_FOLDER" == /* ]]; then
    fix_linkwarden_path "$STORAGE_FOLDER"
fi

######################
# CONFIGURE POSTGRES #
######################

bashio::log.info "Setting postgres..."
if [[ "$DATABASE_URL" == *"localhost"* ]]; then
    echo "... with local database"
    echo "... set database in /config/postgres"
    mkdir -p /config/postgres
    mkdir -p /var/run/postgresql
    chown postgres:postgres /var/run/postgresql
    chown -R postgres:postgres /config/postgres
    chmod 0700 /config/postgres
    # Create folder
    if [ ! -e /config/postgres/postgresql.conf ]; then
        echo "... init folder"
        sudo -u postgres /usr/lib/postgresql/16/bin/initdb -D /config/postgres
    fi
    chown -R postgres:postgres /config/postgres
    chmod 0700 /config/postgres

    echo "... starting server"
    sudo -u postgres service postgresql start
    sleep 5

    echo "... create user and table"
    # Set password
    sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'homeassistant';"

    # Create database if does not exist
    echo "CREATE DATABASE linkwarden; GRANT ALL PRIVILEGES ON DATABASE linkwarden to postgres;
    \q" > setup_postgres.sql
    sudo -u postgres bash -c 'cat setup_postgres.sql | psql "postgres://postgres:homeassistant@localhost:5432"' || true
fi

########################
# CONFIGURE LINKWARDEN #
########################

bashio::log.info "Starting app..."
yarn prisma:deploy && yarn concurrently:start
