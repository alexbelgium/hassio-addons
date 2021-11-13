#!/bin/bash

cd /scripts
for SCRIPTS in *; do
  [ -e "$SCRIPTS" ] || continue 
  echo $SCRIPTS
  chown $(id -u):$(id -g) $SCRIPTS
  chmod a+x $SCRIPTS
  sed -i 's|/usr/bin/with-contenv bashio|/usr/bin/env bashio|g' $SCRIPTS || true
  ./$SCRIPTS &&
  true || true # Prevents script crash on failure
done
