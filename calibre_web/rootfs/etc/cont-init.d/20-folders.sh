#!/bin/bash

if [ ! -d /config ]; then
  echo "Creating /config"
  mkdir -p /config
fi

chown -R "$PUID:$PGID" /config
