#!/bin/bash

if [ ! -d /config/addons_config/calibre ]; then
    echo "Creating /config/addons_config/calibre"
    mkdir -p /config/addons_config/calibre
fi

chown -R abc:abc /config/addons_config/calibre
