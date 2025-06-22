#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Migration
if [ -d /data/database ]; then
	bashio::log.warning "Database migrated to /config"
	mv /data/database /config
fi

if [ -f /homeassistant/addons_config/postgres/config.yaml ]; then
	bashio::log.warning "Config migrated to /config"
	mv /homeassistant/addons_config/postgres/* /config/
	rm -r /homeassistant/addons_config/postgres
	# Correct database location
	sed -i "s|/data/database|/config/database|g" /config/postgresql.conf
fi

# touch sql file
touch /setup_postgres.sql
chmod 755 /setup_postgres.sql
