#!/usr/bin/with-contenv bashio

###########
# FOLDERS #
###########
FILES=$(bashio::config "FilesFolder")
COMICS=$(bashio::config "ComicsFolder")
BOOKS=$(bashio::config "BooksFolder")

jq ".filesPaths.pathString = $FILES" /config/ubooquity/preferences.json
jq ".comicsPaths.pathString = $COMICS" /config/ubooquity/preferences.json
jq ".booksPaths.pathString = $BOOKS" /config/ubooquity/preferences.json

mkdir -p FILES COMICS BOOKS

bashio::log.info "Default folders set. Files : $FILES ; Comics : $COMICS ; Books : $BOOKS"
