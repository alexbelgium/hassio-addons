#!/usr/bin/env bashio

echo "Connecting database to /config/addons_config/fireflyiii"

# Create directory
mkdir -p /config/addons_config/fireflyiii/storage

# Make sure permissions are right
chown -R $(id -u):$(id -g) /config/addons_config/fireflyiii
