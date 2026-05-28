#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# If the Home Assistant MariaDB addon is active, wire its credentials directly
# into BirdNET-Go's config.yaml. Upstream reads MySQL settings only from YAML
# (no env-var overrides exist). Users who prefer SQLite or a different MySQL
# server can set mariadb_disable: true in the addon options.

CONFIG_LOCATION="/config/config.yaml"
MYSQL_DATABASE="birdnet"

if ! bashio::services.available 'mysql'; then
    exit 0
fi

if bashio::config.true 'mariadb_disable'; then
    bashio::log.info "MariaDB auto-configuration disabled by 'mariadb_disable' addon option; skipping."
    exit 0
fi

if [ ! -f "$CONFIG_LOCATION" ]; then
    bashio::log.warning "Skipping MariaDB auto-configuration: $CONFIG_LOCATION not found"
    exit 0
fi

MYSQL_HOST="$(bashio::services 'mysql' 'host')"
MYSQL_PORT="$(bashio::services 'mysql' 'port')"
MYSQL_USER="$(bashio::services 'mysql' 'username')"
MYSQL_PASS="$(bashio::services 'mysql' 'password')"

bashio::log.green "---"
bashio::log.blue "Home Assistant MariaDB addon detected; auto-configuring BirdNET-Go"
bashio::log.blue "Host:     ${MYSQL_HOST}:${MYSQL_PORT}"
bashio::log.blue "User:     ${MYSQL_USER}"
bashio::log.blue "Database: ${MYSQL_DATABASE} (will be created by BirdNET-Go on first connect)"
bashio::log.blue "(Set 'mariadb_disable: true' in addon options to opt out)"
bashio::log.green "---"

# Upstream config.go stores port as a string; pass it as such to match.
# $host / $port / etc. are jq/yq variables, not shell expansions — the
# single quotes around the filter are intentional.
# shellcheck disable=SC2016
yq -i -y \
    --arg host "$MYSQL_HOST" \
    --arg port "$MYSQL_PORT" \
    --arg user "$MYSQL_USER" \
    --arg pass "$MYSQL_PASS" \
    --arg db "$MYSQL_DATABASE" \
    '.output.mysql.enabled = true
     | .output.mysql.host = $host
     | .output.mysql.port = $port
     | .output.mysql.username = $user
     | .output.mysql.password = $pass
     | .output.mysql.database = $db
     | .output.sqlite.enabled = false' \
    "$CONFIG_LOCATION"
