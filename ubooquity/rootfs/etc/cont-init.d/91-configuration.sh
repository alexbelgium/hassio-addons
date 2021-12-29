#!/usr/bin/with-contenv bashio

###########
# FOLDERS #
###########
FILES=$(jq ".filesPaths[0].pathString" /config/addon_config/ubooquity/preferences.json)
COMICS=$(jq ".comicsPaths[0].pathString" /config/addon_config/ubooquity/preferences.json)
BOOKS=$(jq ".booksPaths[0].pathString" /config/addon_config/ubooquity/preferences.json)

mkdir -p $FILES $COMICS $BOOKS /config/addon_config/ubooquity || true
chown -R abc:abc $FILES $COMICS $BOOKS /config/addon_config/ubooquity || true
