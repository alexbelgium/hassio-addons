#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Letta Code stores its database, MemFS, credentials, and settings in ~/.letta
# and works on repositories/files in the workspace directory.
# Both are persisted in /config (the addon_config mount) so state is retained across updates.

bashio::log.info "Configuring persistent storage in /config..."

mkdir -p /config/.letta /config/workspace

if [ ! -L /root/.letta ]; then
    rm -rf /root/.letta
    ln -s /config/.letta /root/.letta
fi

if [ ! -L /workspace ]; then
    rm -rf /workspace
    ln -s /config/workspace /workspace
fi

# App server capability token configuration
if bashio::config.has_value 'token'; then
    bashio::log.info "Using configured App Server token from add-on options"
    bashio::config 'token' > /config/app-server-token
    chmod 600 /config/app-server-token
elif [ ! -f /config/app-server-token ]; then
    bashio::log.info "No token configured. Generating secure random App Server token in /config/app-server-token"
    openssl rand -hex 32 > /config/app-server-token
    chmod 600 /config/app-server-token
    bashio::log.notice "Generated token stored in /config/app-server-token"
fi
