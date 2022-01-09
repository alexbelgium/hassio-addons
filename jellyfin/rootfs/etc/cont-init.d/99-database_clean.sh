#!/bin/bash

#Set variable
db=/config/addons_config/jellyfin/library.db

#Modify base
sqlite3 -quote ${db} "UPDATE TypedBaseItems SET data = replace( data, '/config/jellyfin/', 'config/addons_config/jellyfin/' ), path = replace( path, '/config/jellyfin/', '/config/addons_config/jellyfin/' ) WHERE type='MediaBrowser.Controller.Entities.CollectionFolder';" 
