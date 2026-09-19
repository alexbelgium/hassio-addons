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
            bashio::log.warning "Could not migrate existing data from $resolved_path to $actual_path (may be empty or a permissions issue)"
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

    # Create database if does not exist (UTF8 is required for the ICU collations used by Linkwarden migrations)
    echo "CREATE DATABASE linkwarden TEMPLATE template0 ENCODING 'UTF8' LC_COLLATE 'C' LC_CTYPE 'C'; GRANT ALL PRIVILEGES ON DATABASE linkwarden to postgres;
    \q" > setup_postgres.sql
    sudo -u postgres bash -c 'cat setup_postgres.sql | psql "postgres://postgres:homeassistant@localhost:5432"' || true

    # Databases created by older versions are SQL_ASCII, where the "und-x-icu" collation fails (Prisma P3018/P3009)
    # One-time conversion: copy into a new UTF8 database, keep the original as linkwarden_sql_ascii_backup
    if [ "$(sudo -u postgres psql -tAc "SELECT pg_encoding_to_char(encoding) FROM pg_database WHERE datname='linkwarden'")" = "SQL_ASCII" ]; then
        bashio::log.warning "Database linkwarden uses SQL_ASCII encoding, converting it to UTF8"
        sudo -u postgres psql -v ON_ERROR_STOP=1 -c "DROP DATABASE IF EXISTS linkwarden_utf8;" \
            -c "CREATE DATABASE linkwarden_utf8 TEMPLATE template0 ENCODING 'UTF8' LC_COLLATE 'C' LC_CTYPE 'C';"
        if sudo -u postgres bash -o pipefail -c 'pg_dump -d linkwarden | iconv -f UTF-8 -t UTF-8 | psql -q -v ON_ERROR_STOP=1 -d linkwarden_utf8 >/dev/null'; then
            # Let Prisma re-apply the migration that failed on SQL_ASCII
            sudo -u postgres psql -v ON_ERROR_STOP=1 -d linkwarden_utf8 -c "UPDATE \"_prisma_migrations\" SET rolled_back_at=NOW() WHERE migration_name='20260818000000_case_insensitive_name_sorting' AND finished_at IS NULL AND rolled_back_at IS NULL;"
            sudo -u postgres psql -v ON_ERROR_STOP=1 -c "ALTER DATABASE linkwarden RENAME TO linkwarden_sql_ascii_backup; ALTER DATABASE linkwarden_utf8 RENAME TO linkwarden;"
            bashio::log.info "Database converted to UTF8, original kept as linkwarden_sql_ascii_backup (once everything works, free the space with: sudo -u postgres psql -c 'DROP DATABASE linkwarden_sql_ascii_backup;')"
        else
            sudo -u postgres psql -c "DROP DATABASE IF EXISTS linkwarden_utf8;"
            bashio::log.error "Conversion to UTF8 failed, the original database was left untouched"
        fi
    fi
fi

########################
# CONFIGURE LINKWARDEN #
########################

bashio::log.info "Starting app..."
export PATH="/data_linkwarden/node_modules/.bin:${PATH}"

prisma migrate deploy --schema="/data_linkwarden/packages/prisma/schema.prisma"

exec concurrently -k -n web,worker \
    "cd /data_linkwarden/apps/web && exec next start" \
    "cd /data_linkwarden/apps/worker && exec tsx worker.ts"
