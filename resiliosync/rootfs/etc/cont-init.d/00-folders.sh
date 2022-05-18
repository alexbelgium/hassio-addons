#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

###############
# Define user #
###############

PUID=$(bashio::config "PUID")
PGID=$(bashio::config "PGID")

###################
# Create function #
###################

change_folders () {
  CONFIGLOCATION=$1
  ORIGINALLOCATION=$2
  TYPE=$3
  
    # Inform
    bashio::log.info "Setting $TYPE to $CONFIGLOCATION"

    # Modify files
    echo "Adapting files"
    grep -rl "$ORIGINALLOCATION" /etc/cont-init.d | xargs sed -i "s|$ORIGINALLOCATION|$CONFIGLOCATION|g"
    grep -rl "$ORIGINALLOCATION" /etc/services.d | xargs sed -i "s|$ORIGINALLOCATION|$CONFIGLOCATION|g"
    sed -i "s=$ORIGINALLOCATION=$CONFIGLOCATION=g" /etc/cont-init.d/10-adduser
    sed -i "s=$ORIGINALLOCATION=$CONFIGLOCATION=g" /defaults/*
    #if [ -f $ORIGINALLOCATION/sync.conf ]; then
    #  sed "s|$(jq -r .storage_path "$ORIGINALLOCATION"/sync.conf)||g" $ORIGINALLOCATION/sync.conf
    #fi
    #if [ -f $CONFIGLOCATION/sync.conf ]; then
    #  sed "s|||g" $CONFIGLOCATION/sync.conf
    #fi

    # Create folders
    [ ! -d "$CONFIGLOCATION" ] && echo "Creating $CONFIGLOCATION" && mkdir -p "$CONFIGLOCATION"

    # Transfer files
    [ -d "$,ORIGINALLOCATION" ] && echo "Moving files to $CONFIGLOCATION" && mv "$ORIGINALLOCATION"/* "$CONFIGLOCATION"/ && rmdir "$ORIGINALLOCATION"

    # Set permissions
    echo "Setting ownership to $PUID:$PGID" && chown -R "$PUID":"$PGID" "$CONFIGLOCATION"

}

########################
# Change data location #
########################

change_folders "$(bashio::config 'config_location')" "/share/resiliosync_config" "config_location"
change_folders "$(bashio::config 'data_location')" "/share/resiliosync" "data_location"
