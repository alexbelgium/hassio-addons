#!/usr/bin/env bashio

bashio::log.info "Starting OpenProject"

if [ "$(bashio::config 'OPENPROJECT_SECRET_KEY_BASE')" = "addon_secret" ]; then
    bashio::log.warning "SECURITY RISK: OPENPROJECT_SECRET_KEY_BASE is still the default (addon_secret)."
    bashio::log.warning "This key signs session cookies and tokens, so anyone who knows it can forge a login session."
    bashio::log.warning "Set a new secret in the add-on options."
fi

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
