#!/bin/bash

if [ ! -d /config/addons_config/overseerr ]; then
    echo "Creating /config/addons_config/overseerr"
    mkdir /config/addons_config/overseerr
fi

if [ ! -d /config/.cache/yarn ]; then
    echo "Creating /config/.cache/yarn"
    mkdir /config/.cache/yarn
fi

chown -R abc:abc /config/addons_config/overseerr
chown -R abc:abc /config/.cache/yarn
