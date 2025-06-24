#!/usr/bin/env bashio
# shellcheck shell=bash

POSTGRES_USER="$(bashio::config "POSTGRES_USER" "postgres")"
POSTGRES_DB="$(bashio::config "POSTGRES_DB" "$POSTGRES_USER")"

pg_isready --dbname="${POSTGRES_DB}" --username="${POSTGRES_USER}" || exit $?;