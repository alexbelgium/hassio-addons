#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

####################
# Migrate database #
####################

if [ -f /homeassistant/addons_config/filebrowser/filebrowser.dB ]; then
    echo "Moving database to new location /config"
    cp -rnf /homeassistant/addons_config/filebrowser/* /config/
    rm -r /homeassistant/addons_config/filebrowser
fi

######################
# Link addon folders #
######################

# Clean symlinks
find /config -maxdepth 1 -type l -delete
if [ -d /homeassistant/addons_config ]; then
    find /homeassistant/addons_config -maxdepth 1 -type l -delete
fi

# Remove erroneous folders
if [ -d /homeassistant ]; then
    if [ -d /config/addons_config ]; then
        rm -r /config/addons_config
    fi
    if [ -d /config/addons_autoscripts ]; then
        rm -r /config/addons_autoscripts
    fi
fi

# Create symlinks with legacy folders
if [ -d /homeassistant/addons_config ]; then
    ln -s /homeassistant/addons_config /config
    find /addon_configs/ -maxdepth 1 -mindepth 1 -type d -not -name "*filebrowser*" -exec ln -s {} /config/addons_config/ \;
fi
if [ -d /homeassistant/addons_autoscripts ]; then
    ln -s /homeassistant/addons_autoscripts /config
fi
