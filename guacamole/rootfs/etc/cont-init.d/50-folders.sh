#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

mkdir -p /config/addons_config/guacamole/fonts
mkdir -p /config/addons_config/guacamole/postgres
chmod -R 777 /config
chown -R postgres:postgres /config/addons_config/guacamole/postgres
chmod -R 0700 /config/addons_config/guacamole/postgres
