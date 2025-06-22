#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

####################
# Migrate database #
####################

if [ -d /homeassistant/addons_config/baikal ]; then
	echo "Moving database to new location /config, you won't be able to restore previous versions of the addon"
	cp -rf /homeassistant/addons_config/baikal/* /config/
	rm -r /homeassistant/addons_config/baikal
fi
