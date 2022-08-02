#!/bin/bash

if [ ! -d /config/addons_config/overseerr ]; then
    echo "Creating /config/addons_config/overseerr"
    mkdir /config/addons_config/overseerr
fi

chown -R abc:abc /config/addons_config/overseerr
