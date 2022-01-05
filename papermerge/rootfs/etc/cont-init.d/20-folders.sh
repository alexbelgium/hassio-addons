#!/usr/bin/env bashio

# Create directory
mkdir -p /config/addons_config/papermerge

# Copy previous config if existing
if [ -d /data/config ]; then
  echo "Moving to new location /config/addons_config/papermerge"
  mv /data/config/* /config/addons_config/papermerge/config/
  rm -r /data/config
fi

# Make symlinks
ln -snf -T /config/addons_config/papermerge /data/config

# Make sure permissions are right
chown -R $(id -u):$(id -g) /config/addons_config/papermerge
