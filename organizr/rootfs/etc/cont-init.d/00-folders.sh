#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

if [ ! -d /data/organizr ]; then
	echo "Creating /data/organizr"
	mkdir -p /data/organizr
	chown -R "$PUID:$PGID" /data/organizr
fi
