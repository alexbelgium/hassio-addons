#!/usr/bin/with-contenv bashio

###########
# FOLDERS #
###########
mkdir -p $FILES $COMICS $BOOKS /config/ubooquity
chown -R abc:abc $FILES $COMICS $BOOKS /config/ubooquity

FILES=$(jq ".filesPaths[0].pathString" /config/ubooquity/preferences.json)
COMICS=$(jq ".comicsPaths[0].pathString" /config/ubooquity/preferences.json)
BOOKS=$(jq ".booksPaths[0].pathString" /config/ubooquity/preferences.json)

mkdir -p $FILES $COMICS $BOOKS /config/ubooquity
chown -R abc:abc $FILES $COMICS $BOOKS /config/ubooquity

#FILES='"'$(bashio::config "FilesFolder")'"'
#COMICS='"'$(bashio::config "ComicsFolder")'"'
#BOOKS='"'$(bashio::config "BooksFolder")'"'


#sed -i "s|$CURRENTFILES|$FILES|g" /config/ubooquity/preferences.json
#sed -i "s|$CURRENTCOMICS|$COMICS|g" /config/ubooquity/preferences.json
#sed -i "s|$CURRENTBOOKS|$BOOKS|g" /config/ubooquity/preferences.json

#mkdir -p FILES COMICS BOOKS

#bashio::log.info "Default folders set. Files : $FILES ; Comics : $COMICS ; Books : $BOOKS"
