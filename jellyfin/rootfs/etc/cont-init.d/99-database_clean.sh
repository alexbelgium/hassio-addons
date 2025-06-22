#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

#Set variable
db=%%LOCATION%%/data/data/library.db

#Modify base
if [ -f $db ]; then
	sqlite3 -quote ${db} "UPDATE 'TypedBaseItems' SET data = replace( data, '/config/jellyfin/', '%%LOCATION%%' ), path = replace( path, '/config/jellyfin/', '%%LOCATION%%' ) WHERE type='MediaBrowser.Controller.Entities.CollectionFolder';"
fi
