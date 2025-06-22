#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

####################
# Migrate database #
####################

if [ -f /homeassistant/addons_config/cloudcommander ]; then
	echo "Moving database to new location /config"
	cp -rnf /homeassistant/addons_config/cloudcommander/* /config/ || true
	rm -r /homeassistant/addons_config/cloudcommander
fi

######################
# Link addon folders #
######################

# Clean symlinks
find /config -maxdepth 1 -type l -delete
find /homeassistant/addons_config -maxdepth 1 -type l -delete

# Remove erroneous folders
if [ -d /homeassistant ]; then
	if [ -d /config/addons_config ]; then
		rm -r /config/addons_config
	fi
	if [ -d /config/addons_autoscripts ]; then
		rm -r /config/addons_autoscripts
	fi
fi

# Create symlinks
ln -s /homeassistant/addons_config /config
ln -s /homeassistant/addons_autoscripts /config
find /addon_configs/ -maxdepth 1 -mindepth 1 -type d -not -name "*cloudcommander*" -exec ln -s {} /config/addons_config/ \;

#################
# NGINX SETTING #
#################

# declare port
# declare certfile
declare ingress_interface
declare ingress_port
# declare keyfile

CLOUDCMD_PREFIX=$(bashio::addon.ingress_entry)
export CLOUDCMD_PREFIX

declare ADDON_PROTOCOL=http
if bashio::config.true 'ssl'; then
	ADDON_PROTOCOL=https
	bashio::config.require.ssl
fi

# port=$(bashio::addon.port 80)
ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)
sed -i "s|%%protocol%%|${ADDON_PROTOCOL}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%port%%|${ingress_port}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%interface%%|${ingress_interface}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%subpath%%|${CLOUDCMD_PREFIX}/|g" /etc/nginx/servers/ingress.conf
mkdir -p /var/log/nginx && touch /var/log/nginx/error.log

###############
# LAUNCH APPS #
###############

if bashio::config.has_value 'CUSTOM_OPTIONS'; then
	CUSTOMOPTIONS=" $(bashio::config 'CUSTOM_OPTIONS')"
else
	CUSTOMOPTIONS=""
fi

if bashio::config.has_value 'DROPBOX_TOKEN'; then
	DROPBOX_TOKEN="--dropbox --dropbox-token $(bashio::config 'DROPBOX_TOKEN')"
else
	DROPBOX_TOKEN=""
fi

bashio::log.info "Starting..."

cd /
./usr/src/app/bin/cloudcmd.mjs '"'"$DROPBOX_TOKEN""$CUSTOMOPTIONS"'"' &
bashio::net.wait_for 8000 localhost 900 || true
bashio::log.info "Started !"
exec nginx
