#!/bin/bash

#for SCRIPTS in "/00-.sh" "/00-banner.sh" "/99-run.sh"; do
cd /scripts
for SCRIPTS in /scripts/*; do
  [ -e "$SCRIPTS" ] || continue 
  echo $SCRIPTS
  chown $(id -u):$(id -g) $SCRIPTS
  chmod a+x $SCRIPTS
  sed -i 's|/usr/bin/with-contenv bashio|/usr/bin/env bashio|g' $Scripts || true
  /.$SCRIPTS &&
  true || true # Prevents script crash on failure
done
