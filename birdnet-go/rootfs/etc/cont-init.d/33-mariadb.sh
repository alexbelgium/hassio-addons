#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# When the Home Assistant MariaDB addon is active, optionally wire its
# credentials directly into BirdNET-Go's config.yaml. Upstream reads MySQL
# settings only from YAML (no env-var overrides exist), so this is the only
# way to auto-configure them. The behaviour is opt-in via the
# mariadb_auto_config addon option. When the option is off but MariaDB is
# detected, we log a one-shot hint pointing users at the option.

CONFIG_LOCATION="/config/config.yaml"
MYSQL_DATABASE="birdnet"

if ! bashio::services.available 'mysql'; then
    exit 0
fi

MYSQL_HOST="$(bashio::services 'mysql' 'host')"
MYSQL_PORT="$(bashio::services 'mysql' 'port')"
MYSQL_USER="$(bashio::services 'mysql' 'username')"
MYSQL_PASS="$(bashio::services 'mysql' 'password')"

if ! bashio::config.true 'mariadb_auto_config'; then
    bashio::log.green "---"
    bashio::log.yellow "Home Assistant MariaDB addon detected. Set 'mariadb_auto_config: true' in the addon options to wire it into BirdNET-Go automatically (and disable SQLite). Connection details:"
    bashio::log.blue "Database user    : ${MYSQL_USER}"
    bashio::log.blue "Database password: ${MYSQL_PASS}"
    bashio::log.blue "Database name    : ${MYSQL_DATABASE}"
    bashio::log.blue "Host-name        : ${MYSQL_HOST}"
    bashio::log.blue "Port             : ${MYSQL_PORT}"
    bashio::log.green "---"
    exit 0
fi

if [ ! -f "$CONFIG_LOCATION" ]; then
    bashio::log.warning "Skipping MariaDB auto-configuration: $CONFIG_LOCATION not found"
    exit 0
fi

bashio::log.green "---"
bashio::log.blue "mariadb_auto_config enabled; writing Home Assistant MariaDB credentials into BirdNET-Go config and disabling SQLite"
bashio::log.blue "Host:     ${MYSQL_HOST}:${MYSQL_PORT}"
bashio::log.blue "User:     ${MYSQL_USER}"
bashio::log.blue "Database: ${MYSQL_DATABASE} (will be created by BirdNET-Go on first connect)"
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
