#!/usr/bin/env bashio

echo "Connecting database to /config/addons_config/fireflyiii"

# Create directory
mkdir -p /data/firefly
mkdir -p /config/addons_config/fireflyiii/storage

# Make sure permissions are right
chown -R $(id -u):$(id -g) /config/addons_config/fireflyiii

# Make symlink
cp -r /var/www/html/storage /config/addons_config/fireflyiii/storage
rm -r /data/firefly/storage
ln -sf /config/addons_config/fireflyiii/storage /data/firefly/storage
