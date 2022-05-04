#!/bin/bash
# shellcheck shell=bash

#CONFIGSOURCE=$(bashio::config "CONFIG_LOCATION")
#CONFIGSOURCE=$(dirname "$CONFIGSOURCE")
CONFIGSOURCE="/config/addons_config/zoneminder"

# Create directory
echo "... making sure $CONFIGSOURCE exists"
mkdir -p "$CONFIGSOURCE"/{events,images,temp} || true

# Make sure permissions are right
echo "... checking permissions"
chown -R "$(id -u):$(id -g)" "$CONFIGSOURCE"

# Make symlinks
echo "... making symlinks"
rm -rf /var/cache/zoneminder/events
rm -rf /var/cache/zoneminder/images
rm -rf /var/cache/zoneminder/temp
ln -s "$CONFIGSOURCE"/events /var/cache/zoneminder/events
ln -s "$CONFIGSOURCE"/images /var/cache/zoneminder/images
ln -s "$CONFIGSOURCE"/temp /var/cache/zoneminder/temp
