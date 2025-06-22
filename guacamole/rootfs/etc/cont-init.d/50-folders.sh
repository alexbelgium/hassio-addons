#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

mkdir -p /config/fonts
mkdir -p /config/postgres
chown -R postgres:postgres /config/postgres
chmod -R 0700 /config/postgres
