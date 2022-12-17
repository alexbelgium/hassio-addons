#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

#LOCATION=$(bashio::config 'data_location')
#if [[ "$LOCATION" = "null" || -z "$LOCATION" ]]; then LOCATION=/config/addons_config/${HOSTNAME#*-}; fi

#Set variable
db=/config/jellyfin/data/data/library.db

#Modify base
if [ -f $db ]; then
    sqlite3 -quote ${db} "UPDATE 'TypedBaseItems' SET data = replace( data, '/config/jellyfin/', '%%LOCATION%%' ), path = replace( path, '/config/jellyfin/', '%%LOCATION%%' ) WHERE type='MediaBrowser.Controller.Entities.CollectionFolder';"
fi
