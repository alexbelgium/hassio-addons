#!/bin/bash

###########
# SCRIPTS #
###########

#for SCRIPTS in /scripts/*.sh; do
 
for SCRIPTS in "/00-.sh" "/00-banner.sh" "/99-run.sh"; do
  [ -e "$SCRIPTS" ] || continue 
  echo $SCRIPTS
  chown $(id -u):$(id -g) $SCRIPTS
  chmod a+x $SCRIPTS
  sed -i 's|/usr/bin/with-contenv bashio|/usr/bin/env bashio|g' $SCRIPTS
  /.$SCRIPTS &&
  true # Prevents script crash on failure
done
