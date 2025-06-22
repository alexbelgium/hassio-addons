#!/bin/bash

if [ ! -d /share/storage/movies ]; then
	echo "Creating /share/storage/movies"
	mkdir -p /share/storage/movies
	chown -R "$PUID:$PGID" /share/storage/movies
fi

if [ ! -d /share/downloads ]; then
	echo "Creating /share/downloads"
	mkdir -p /share/downloads
	chown -R "$PUID:$PGID" /share/downloads
fi

if [ -d /config/radarr ] && [ ! -d /config/addons_config/radarr ]; then
	echo "Moving to new location /config/addons_config/radarr"
	mkdir -p /config/addons_config/radarr
	chown -R "$PUID:$PGID" /config/addons_config/radarr
	mv /config/radarr/* /config/addons_config/radarr/
	rm -r /config/radarr
fi

if [ ! -d /config/addons_config/radarr ]; then
	echo "Creating /config/addons_config/radarr"
	mkdir -p /config/addons_config/radarr
	chown -R "$PUID:$PGID" /config/addons_config/radarr
fi
