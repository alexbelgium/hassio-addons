#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# INITALISATION #
#################

bashio::log.info "Creating folders"
mkdir -p "$STORAGE_FOLDER"

# Linkwarden resolves STORAGE_FOLDER relative to its monorepo root via:
#   path.join(process.cwd(), '../..', STORAGE_FOLDER, filePath)
# When the app runs from /data_linkwarden/apps/web, an absolute STORAGE_FOLDER
# (e.g. /config/library) is resolved to /data_linkwarden/config/library instead
# of /config/library. Create a symlink so data reaches the persistent location.
if [[ "$STORAGE_FOLDER" == /* ]]; then
    RESOLVED_STORAGE="/data_linkwarden${STORAGE_FOLDER}"
    if [ "$RESOLVED_STORAGE" != "$STORAGE_FOLDER" ]; then
        mkdir -p "$(dirname "$RESOLVED_STORAGE")"
        # Preserve any data already written to the non-persistent path
        if [ -d "$RESOLVED_STORAGE" ] && [ ! -L "$RESOLVED_STORAGE" ]; then
            cp -rn "$RESOLVED_STORAGE/." "$STORAGE_FOLDER/" 2>/dev/null || true
            rm -rf "$RESOLVED_STORAGE"
        fi
        ln -sfn "$STORAGE_FOLDER" "$RESOLVED_STORAGE"
        bashio::log.info "Symlinked $RESOLVED_STORAGE -> $STORAGE_FOLDER"
    fi
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
