#!/usr/bin/env bashio

bashio::log.info "Starting OpenProject"

# Ensure persistence for PGDATA and asset folders
for folder in pg assets; do
    mkdir -p /config/"$folder"
    if [ -d /data/"$folder" ] && [ "$(ls -A /data/"$folder")" ]; then
        # Copy only if source is non-empty
        cp -a /data/"$folder"/. /config/"$folder"/
        rm -rf /data/"$folder"
    fi
    chmod 700 /config/"$folder"
done

echo "Setting permissions"
mkdir -p /config/assets/files
chown -R postgres:postgres /config

cd /app || true

exec ./docker/prod/entrypoint.sh ./docker/prod/supervisord
