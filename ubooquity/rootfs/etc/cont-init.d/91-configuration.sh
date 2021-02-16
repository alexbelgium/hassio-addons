#!/usr/bin/with-contenv bashio

###########
# FOLDERS #
###########
FILES='"'$(bashio::config "FilesFolder")'"'
COMICS='"'$(bashio::config "ComicsFolder")'"'
BOOKS='"'$(bashio::config "BooksFolder")'"'

CURRENTFILES=$(jq ".filesPaths[0].pathString" /config/ubooquity/preferences.json)
CURRENTCOMICS=$(jq ".comicsPaths[0].pathString" /config/ubooquity/preferences.json)
CURRENTBOOKS=$(jq ".booksPaths[0].pathString" /config/ubooquity/preferences.json)

sed -i "s|$CURRENTFILES|$FILES|g" /config/ubooquity/preferences.json
sed -i "s|$CURRENTCOMICS|$COMICS|g" /config/ubooquity/preferences.json
sed -i "s|$CURRENTBOOKS|$BOOKS|g" /config/ubooquity/preferences.json

mkdir -p FILES COMICS BOOKS

bashio::log.info "Default folders set. Files : $FILES ; Comics : $COMICS ; Books : $BOOKS"
