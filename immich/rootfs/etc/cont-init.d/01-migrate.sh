#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

PREVIOUS_FOLDER="immich"

# Move main folder
if [ -f /homeassistant/addons_config/"$PREVIOUS_FOLDER"/config.yaml ]; then
  bashio::log.warning "----------------------------------------"
  bashio::log.warning "Migrating configuration to the new addon"
  bashio::log.warning "----------------------------------------"
  cp -rnp /homeassistant/addons_config/"$PREVIOUS_FOLDER"/ /config/
  mv /homeassistant/addons_config/"$PREVIOUS_FOLDER" "$PREVIOUS_FOLDER"_migrated
  if [ -d /config/addons_config ]; then rm -r /config/addons_config; fi
  echo "Files moved to /addon_configs/$HOSTNAME"
fi

# Move autoscript
if [ -f /homeassistant/addons_autoscrips/immich.sh ]; then
  cp -rnf /homeassistant/addons_autoscrips/"$PREVIOUS_FOLDER".sh /config/ &>/dev/null || true
  bashio::log.yellow "... moved $PREVIOUS_FOLDER.sh from /config/addons_autoscripts to /addon_configs/$HOSTNAME"
fi
