#!/usr/bin/env bashio

# Create directory
mkdir -p /config/addons_config/fireflyiii

# Make sure permissions are right
chown -R $(id -u):$(id -g) /config/addons_config/fireflyiii
