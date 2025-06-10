#!/bin/bash

if [ -d /config/prowlarr ] && [ ! -d /config/addons_config/prowlarr ]; then
	echo "Moving to new location /config/addons_config/prowlarr"
	mkdir -p /config/addons_config/prowlarr
	chown -R "$PUID:$PGID" /config/addons_config/prowlarr
	mv /config/prowlarr/* /config/addons_config/prowlarr/
	rm -r /config/prowlarr
fi

if [ ! -d /config/addons_config/prowlarr ]; then
	echo "Creating /config/addons_config/prowlarr"
	mkdir -p /config/addons_config/prowlarr
	chown -R "$PUID:$PGID" /config/addons_config/prowlarr
fi
