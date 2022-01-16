#!/usr/bin/env bashio

# Create directory
mkdir -p /config/addons_config/fireflyiii

# Make sure permissions are right
chmod -R 755 /config/addons_config
chown -R $(id -u):$(id -g) /config/addons_config/fireflyiii
