#!/usr/bin/env bashio

bashio::log.info "Starting OpenProject"

for folders in pg assets; do
    mkdir -p /config/"$folders"/
    if [ -d /data/"$folders" ]; then
        bashio::log.warning "Migrating /data/$folders to /config/$folders"
        cp -rf /data/"$folders"/ /config/"$folders"/
        rm -r /data/"$folders"
    fi
done

cd /app || true

exec ./docker/prod/entrypoint.sh ./docker/prod/supervisord
