#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

bashio::log.info "Preparing scripts"
echo "... creating structure"
mkdir -p \
  /data/photoprism/originals \
  /data/photoprism/import \
  /data/photoprism/storage/config \
  /data/photoprism/backup \
  /data/photoprism/storage/cache

echo "... setting permissions"
chmod -R 777 /data/photoprism
chown -Rf photoprism:photoprism /data/photoprism
chmod -Rf a+rwx /data/photoprism
