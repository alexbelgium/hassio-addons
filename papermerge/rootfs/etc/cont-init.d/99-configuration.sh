#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

##################
# SELECT FOLDERS #
##################

#Set media dir
MEDIADIR=$(bashio::config 'storage_dir')
#clean data
sed -i '/MEDIA_DIR/d' /data/config/papermerge.conf.py
#add data
sed -i "2 i\MEDIA_DIR = \"$MEDIADIR\"" /data/config/papermerge.conf.py
bashio::log.info "Storage dir set to $MEDIADIR"

#Set import dir
IMPORTDIR=$(bashio::config 'import_dir')
#clean data
sed -i '/IMPORTER_DIR/d' /data/config/papermerge.conf.py || true
#add data
sed -i "2 i\IMPORTER_DIR = \"$IMPORTDIR\"" /data/config/papermerge.conf.py
bashio::log.info "Import dir set to $IMPORTDIR"

##################
# CREATE FOLDERS #
##################

if [ ! -d /config ]; then
  echo "Creating /config"
  mkdir -p /config
fi
chown -R abc:abc /config

if [ ! -d "$MEDIADIR" ]; then
  echo "Creating $MEDIADIR"
  mkdir -p "$MEDIADIR"
fi
chown -R abc:abc "$MEDIADIR"

if [ ! -d "$IMPORTDIR" ]; then
  echo "Creating $IMPORTDIR"
  mkdir -p "$IMPORTDIR"
fi
chown -R abc:abc "$IMPORTDIR"
