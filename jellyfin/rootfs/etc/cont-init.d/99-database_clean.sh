#!/bin/bash

#Set variable
db=/config/addons_config/jellyfin/data/data/library.db

#Modify base
if [ -f $db ]; then
    sqlite3 -quote ${db} "UPDATE 'TypedBaseItems' SET data = replace( data, '/config/jellyfin/', '/config/addons_config/jellyfin/' ), path = replace( path, '/config/jellyfin/', '/config/addons_config/jellyfin/' ) WHERE type='MediaBrowser.Controller.Entities.CollectionFolder';"
fi
