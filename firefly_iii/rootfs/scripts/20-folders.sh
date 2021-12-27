#!/usr/bin/env bashio

echo "Connecting database to /config/addons_config/firefly_iii"

# Create directory
mkdir -p /config/addons_config/firefly_iii

# Make sure permissions are right
chown $(id -u):$(id -g) /config/addons_config/firefly_iii

# Make symlink
ln -snf /var/www/html/storage /config/addons_config/firefly_iii
