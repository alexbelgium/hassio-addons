#!/usr/bin/env bashio

echo "Connecting database to /config/addons_config/fireflyiii"

# Create directory
mkdir -p /config/addons_config/fireflyiii/storage

# Make sure permissions are right
chown $(id -u):$(id -g) /config/addons_config/fireflyiii

# Make symlink
rm -r /var/www/html/storage
ln -s /config/addons_config/fireflyiii/storage /var/www/html
