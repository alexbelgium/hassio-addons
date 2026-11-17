#!/usr/bin/env bashio

bashio::log.info "Starting OpenProject"

# Shipped defaults: addon_secret (config.yaml "environment") and OVERWRITE_ME
# (SECRET_KEY_BASE in the upstream image)
if [[ "${OPENPROJECT_SECRET_KEY_BASE:-}" == addon_secret || "${SECRET_KEY_BASE:-}" =~ ^(addon_secret|OVERWRITE_ME)$ ]]; then
    bashio::log.warning "SECURITY RISK: the OpenProject secret key base is still a shipped default."
    bashio::log.warning "This key signs session cookies and tokens, so anyone who knows it can forge a login session."
    bashio::log.warning "Set a long random value in the OPENPROJECT_SECRET_KEY_BASE option and as SECRET_KEY_BASE in env_vars."
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
