#!/usr/bin/env bashio
# shellcheck shell=bash

# The server is deliberately down while the cluster is upgraded to a new PostgreSQL major, which
# can outlast the start period: reporting unhealthy would have the watchdog restart it halfway
[ ! -e /run/postgres_upgrading ] || exit 0

POSTGRES_USER="$(bashio::config "POSTGRES_USER" "postgres")"
POSTGRES_DB="$(bashio::config "POSTGRES_DB" "$POSTGRES_USER")"

pg_isready --dbname="${POSTGRES_DB}" --username="${POSTGRES_USER}" || exit $?
