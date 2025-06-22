#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

####################
# Migrate database #
####################

if [ -d /homeassistant/addons_config/calibre ]; then
	echo "Moving database to new location /config"
	cp -rf /homeassistant/addons_config/calibre/* /config/
	rm -r /homeassistant/addons_config/calibre
fi

# Legacy path
if [ -d /config/addons_config/calibre ]; then rm -r /config/addons_config/calibre; fi
mkdir -p /config/addons_config/calibre
ln -s "/config/Calibre Library" "/config/addons_config/calibre/"
chmod -R 777 /config/addons_config
