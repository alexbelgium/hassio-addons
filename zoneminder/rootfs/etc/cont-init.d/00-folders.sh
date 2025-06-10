#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

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
if [ ! -d "$CONFIGSOURCE"/sounds ]; then mkdir "$CONFIGSOURCE"/sounds; fi
if [ ! -d "$IMAGESOURCE" ]; then mkdir "$IMAGESOURCE"; fi

# Make sure permissions are right
echo "... checking permissions"
chown -R "$(id -u):$(id -g)" "$CONFIGSOURCE"
chown -R "$(id -u):$(id -g)" "$IMAGESOURCE"

# Make symlinks
echo "... making symlinks"
ln -s "$CONFIGSOURCE"/events /var/cache/zoneminder/events2
ln -s "$CONFIGSOURCE"/sounds /var/cache/zoneminder/sounds2
ln -s "$IMAGESOURCE" /var/cache/zoneminder/images2
