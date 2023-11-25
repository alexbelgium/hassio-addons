#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

####################
# Migrate database #
####################

if [ -f /config/addons_config/filebrowser/filebrowser.d* ]; then
    echo "Moving database to new location /config"
    mkdir -p /config
    chmod 777 /config
    cp -rnf /config/addons_config/filebrowser/* /config/
    rm -r /config/addons_config/filebrowser
fi

######################
# Link addon folders #
######################

# Clean symlinks
find /config -maxdepth 1 -type l -delete
find /homeassistant/addons_config -maxdepth 1 -type l -delete
# Create symlinks
ln -fs /homeassistant/addons_config /config
ln -fs /homeassistant/addons_autoscripts /config
for folders in $(find /addon_configs -maxdepth 1 -type d -not -name "*filebrowser*"); do
  ln -fs ${folders} /config/addons_config
done
