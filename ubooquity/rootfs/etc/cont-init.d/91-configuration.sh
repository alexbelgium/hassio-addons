#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

###########
# FOLDERS #
###########
FILES=$(jq ".filesPaths[0].pathString" /config/addons_config/ubooquity/preferences.json)
COMICS=$(jq ".comicsPaths[0].pathString" /config/addons_config/ubooquity/preferences.json)
BOOKS=$(jq ".booksPaths[0].pathString" /config/addons_config/ubooquity/preferences.json)

mkdir -p "$FILES" "$COMICS" "$BOOKS" /config/addons_config/ubooquity || true
chown -R "$PUID:$PGID" "$FILES" "$COMICS" "$BOOKS" /config/addons_config/ubooquity || true
