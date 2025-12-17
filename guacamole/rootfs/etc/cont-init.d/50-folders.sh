#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

mkdir -p /config/fonts
mkdir -p /config/postgres
mkdir -p /config/postgres/pg_stat_tmp
chown -R postgres:postgres /config/postgres
chmod -R 0700 /config/postgres
