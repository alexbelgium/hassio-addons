#!/usr/bin/env bashio

bashio::log.info "Starting OpenProject"

# Ensure persistence for PGDATA and asset folders
for folder in pg assets; do
	mkdir -p /data/"$folder"
	if [ -d /config/"$folder" ] && [ "$(ls -A /config/"$folder"/)" ]; then
		# Copy only if source is non-empty
		cp -rf /config/"$folder"/. /data/"$folder"/
		rm -rf /config/"$folder"
	fi
	chmod 700 /data/"$folder"
done

echo "Setting permissions"
mkdir -p /data/assets/files
chown -R postgres:postgres /data

cd /app || true

exec ./docker/prod/entrypoint.sh ./docker/prod/supervisord
