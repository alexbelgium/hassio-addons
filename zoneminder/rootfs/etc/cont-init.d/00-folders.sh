#!/bin/bash
# shellcheck shell=bash

#CONFIGSOURCE=$(bashio::config "CONFIG_LOCATION")
#CONFIGSOURCE=$(dirname "$CONFIGSOURCE")
CONFIGSOURCE="/config/addons_config/zoneminder"

# Set image location
if bashio::config.has_value "Images_location"; then
  IMAGESOURCE=$(bashio::config "Images_location")
else
  IMAGESOURCE="$CONFIGSOURCE"/images
fi

# Create directory
echo "... making sure $CONFIGSOURCE exists"
if [ ! -d "$CONFIGSOURCE" ]; then mkdir "$CONFIGSOURCE"; fi
if [ ! -d "$CONFIGSOURCE"/events ]; then mkdir "$CONFIGSOURCE"/events; fi
if [ ! -d "$IMAGESOURCE" ]; then mkdir "$IMAGESOURCE"; fi

# Make sure permissions are right
echo "... checking permissions"
chown -R "$(id -u):$(id -g)" "$CONFIGSOURCE"
chown -R "$(id -u):$(id -g)" "$IMAGESOURCE"

# Make symlinks
echo "... making symlinks"
rm -rf /var/cache/zoneminder/events
rm -rf /var/cache/zoneminder/images
ln -s "$CONFIGSOURCE"/events /var/cache/zoneminder/events
ln -s "$IMAGESOURCE" /var/cache/zoneminder/images
