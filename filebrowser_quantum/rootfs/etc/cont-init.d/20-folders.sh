#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

####################
# Migrate database #
####################

if [ -f /homeassistant/addons_config/filebrowser_quantum/filebrowser_quantum.db ]; then
    echo "Moving database from legacy addons_config location to /config"
    cp -rnf /homeassistant/addons_config/filebrowser_quantum/* /config/
    rm -r /homeassistant/addons_config/filebrowser_quantum
fi

if [ ! -f /config/filebrowser_quantum.db ] && [ -f /homeassistant/addon_configs/db21ed7f_filebrowser_quantum/filebrowser_quantum.db ]; then
    echo "Moving database from addon_configs location to /config"
    cp -rnf /homeassistant/addon_configs/db21ed7f_filebrowser_quantum/* /config/
fi

######################
# Link addon folders #
######################

# Clean symlinks
find /config -maxdepth 1 -type l -delete
if [ -d /homeassistant/addons_config ]; then
    find /homeassistant/addons_config -maxdepth 1 -type l -delete
fi
if [ -d /homeassistant/addon_configs ]; then
    find /homeassistant/addon_configs -maxdepth 1 -type l -delete
fi

# Remove erroneous folders
if [ -d /homeassistant ]; then
    if [ -d /config/addons_config ]; then
        rm -r /config/addons_config
    fi
    if [ -d /config/addon_configs ]; then
        rm -r /config/addon_configs
    fi
    if [ -d /config/addons_autoscripts ]; then
        rm -r /config/addons_autoscripts
    fi
fi

# Create symlinks with legacy folders
if [ -d /homeassistant/addons_config ]; then
    ln -s /homeassistant/addons_config /config
    find /addon_configs/ -maxdepth 1 -mindepth 1 -type d -not -name "*filebrowser_quantum*" -exec ln -s {} /config/addons_config/ \;
elif [ -d /homeassistant/addon_configs ]; then
    ln -s /homeassistant/addon_configs /config
    find /addon_configs/ -maxdepth 1 -mindepth 1 -type d -not -name "*filebrowser_quantum*" -exec ln -s {} /config/addon_configs/ \;
fi
if [ -d /homeassistant/addons_autoscripts ]; then
    ln -s /homeassistant/addons_autoscripts /config
fi
