#!/bin/bash

if [ ! -d /share/storage/movies ]; then
	echo "Creating /share/storage/movies"
	mkdir -p /share/storage/movies
	chown -R "$PUID:$PGID" /share/storage/movies
fi

if [ ! -d /share/storage/tv ]; then
	echo "Creating /share/storage/tv"
	mkdir -p /share/storage/tv
	chown -R "$PUID:$PGID" /share/storage/tv
fi

if [ ! -d /share/downloads ]; then
	echo "Creating /share/downloads"
	mkdir -p /share/downloads
	chown -R "$PUID:$PGID" /share/downloads
fi

if [ -d /config/bazarr ] && [ ! -d /config/addons_config/bazarr ]; then
	echo "Moving to new location /config/addons_config/bazarr"
	mkdir -p /config/addons_config/bazarr
	chown -R "$PUID:$PGID" /config/addons_config/bazarr
	mv /config/bazarr/* /config/addons_config/bazarr/
	rm -r /config/bazarr
fi

if [ ! -d /config/addons_config/bazarr ]; then
	echo "Creating /config/addons_config/bazarr"
	mkdir -p /config/addons_config/bazarr
	chown -R "$PUID:$PGID" /config/addons_config/bazarr
fi
