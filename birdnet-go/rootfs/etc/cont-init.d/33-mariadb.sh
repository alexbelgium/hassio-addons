#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# When the Home Assistant MariaDB addon is active, optionally wire its
# credentials directly into BirdNET-Go's config.yaml. Upstream reads MySQL
# settings only from YAML (no env-var overrides exist), so this is the only
# way to auto-configure them. The behaviour is opt-in via the
# mariadb_auto_config addon option.
#
# When the option is off but MariaDB is detected, we log a one-shot hint and
# ensure config.yaml falls back to SQLite (reverting any previously written
# mysql block). This is safe because BirdNET-Go's config.yaml defaults to
# SQLite and the mysql block is only ever written by this script.
#
# When the option is on we:
#   1. Create the "birdnet" database if it does not already exist — birdnet-go
#      connects to an existing schema and does not create it automatically.
#   2. Write the MySQL credentials into config.yaml and disable SQLite.

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
    bashio::log.yellow "Home Assistant MariaDB addon detected but mariadb_auto_config is disabled; ensuring BirdNET-Go uses SQLite."
    bashio::log.yellow "Set 'mariadb_auto_config: true' in the addon options to wire MariaDB into BirdNET-Go automatically. Connection details:"
    bashio::log.blue "Database user    : ${MYSQL_USER}"
    bashio::log.blue "Database password: [redacted]"
    bashio::log.blue "Database name    : ${MYSQL_DATABASE}"
    bashio::log.blue "Host-name        : ${MYSQL_HOST}"
    bashio::log.blue "Port             : ${MYSQL_PORT}"
    bashio::log.green "---"
    if [ -f "$CONFIG_LOCATION" ]; then
        # Revert any previously written mysql block so the app uses SQLite.
        # shellcheck disable=SC2016
        yq -i -y \
            '.output.mysql.enabled = false
             | .output.sqlite.enabled = true' \
            "$CONFIG_LOCATION"
    fi
    exit 0
fi

if [ ! -f "$CONFIG_LOCATION" ]; then
    bashio::log.warning "Skipping MariaDB auto-configuration: $CONFIG_LOCATION not found"
    exit 0
fi

bashio::log.green "---"
bashio::log.blue "mariadb_auto_config enabled; creating MariaDB database and wiring credentials into BirdNET-Go config"
bashio::log.blue "Host:     ${MYSQL_HOST}:${MYSQL_PORT}"
bashio::log.blue "User:     ${MYSQL_USER}"
bashio::log.blue "Database: ${MYSQL_DATABASE}"
bashio::log.green "---"

# Create the database — birdnet-go connects to an existing schema and does NOT
# create it automatically, so we must do it here. MYSQL_PWD avoids exposing
# the password via the process command line.
if ! MYSQL_PWD="${MYSQL_PASS}" mysql \
    --host="${MYSQL_HOST}" \
    --port="${MYSQL_PORT}" \
    --user="${MYSQL_USER}" \
    --connect-timeout=10 \
    -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null; then
    bashio::log.error "Failed to create MariaDB database '${MYSQL_DATABASE}' — verify the MariaDB addon is running and the user has CREATE DATABASE privileges"
    exit 1
fi
bashio::log.blue "Database '${MYSQL_DATABASE}' is ready"

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
