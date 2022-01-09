#!/bin/bash

#Set variable
db=/config/addons_config/jellyfin/library.db

#Modify base
if [ -f $db ]; then
sqlite3 -quote ${db} "UPDATE TypedBaseItems SET data = replace( data, '/config/jellyfin/', 'config/addons_config/jellyfin/' ) WHERE data LIKE '/config/jellyfin/%'; UPDATE TypedBaseItems SET path = replace( path, '/config/jellyfin/', 'config/addons_config/jellyfin/' ) WHERE path LIKE '/config/jellyfin/%';" 
fi
