#!/bin/bash

if [ ! -d /config/addons_config/calibre-web ]; then
    echo "Creating /config/addons_config/calibre-web"
    mkdir -p /config/addons_config/calibre-web
fi

chown -R "$PUID:$PGID" /config/addons_config/calibre-web
