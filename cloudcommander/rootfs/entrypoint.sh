#!/bin/bash

echo "Starting scripts :"
for SCRIPTS in scripts/*; do
  [ -e "$SCRIPTS" ] || continue
  echo "$SCRIPTS: executing"
  chown $(id -u):$(id -g) $SCRIPTS
  chmod a+x $SCRIPTS
  sed -i 's|/usr/bin/with-contenv bashio|/usr/bin/env bashio|g' $SCRIPTS || true
  ./$SCRIPTS || echo "$SCRIPTS: exiting $?"
done
