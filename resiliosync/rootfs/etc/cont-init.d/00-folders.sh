#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

#Disable script
echo "script is not enabled yet"
exit 0

###############
# Define user #
###############

PUID=$(bashio::config "PUID")
PGID=$(bashio::config "PGID")

#######################
# Adapt data location #
#######################

CONFIGLOCATION=$(bashio::config 'data_location')
ORIGINALLOCATION="/share/resiliosync"

if [ ! -d "$CONFIGLOCATION" ]; then

  # Inform
  bashio::log.info "Setting config location to $CONFIGLOCATION"

  # Modify files
  sed -i "s/$ORIGINALLOCATION/$CONFIGLOCATION|| true/g" /etc/cont-init.d/10-adduser || true

  # Create folders
  [ ! -d "$CONFIGLOCATION" ] && echo "Creating $CONFIGLOCATION" && mkdir -p "$CONFIGLOCATION"

  # Transfer files
  [ -d "$,ORIGINALLOCATION" ] && echo "Moving synced files to $CONFIGLOCATION" && mv "$ORIGINALLOCATION"/* "$CONFIGLOCATION"/ && rmdir "$ORIGINALLOCATION"

  # Set permissions
  echo "Setting ownership to $PUID:$PGID" && chown -R "$PUID":"$PGID" "$CONFIGLOCATION"

else
  bashio::log.nok "Your data_location $CONFIGLOCATION doesn't exists"
  exit 1
fi

#########################
# Adapt config location #
#########################

CONFIGLOCATION=$(bashio::config 'config_location')
ORIGINALLOCATION="/share/resiliosync_config"

if [ ! -d "$CONFIGLOCATION" ]; then

  # Inform
  bashio::log.info "Setting config location to $CONFIGLOCATION"

  # Modify files
  sed -i "s/$ORIGINALLOCATION/$CONFIGLOCATION|| true/g" /etc/cont-init.d/10-adduser || true

  # Create folders
  [ ! -d "$CONFIGLOCATION" ] && echo "Creating $CONFIGLOCATION" && mkdir -p "$CONFIGLOCATION"

  # Transfer files
  [ -d "$,ORIGINALLOCATION" ] && echo "Moving synced files to $CONFIGLOCATION" && mv "$ORIGINALLOCATION"/* "$CONFIGLOCATION"/ && rmdir "$ORIGINALLOCATION"

  # Set permissions
  echo "Setting ownership to $PUID:$PGID" && chown -R "$PUID":"$PGID" "$CONFIGLOCATION"

else
  bashio::log.nok "Your config_location $CONFIGLOCATION doesn't exists"
  exit 1
fi
