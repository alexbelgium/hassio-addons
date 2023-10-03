#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

mkdir -p /config/addons_config/guacamole/fonts
mkdir -p /config/addons_config/guacamole/postgres
chown -R postgres:postgres /config/addons_config/guacamole/postgres
chmod -R 0700 /config/addons_config/guacamole/postgres
