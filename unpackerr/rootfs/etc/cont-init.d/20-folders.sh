#!/bin/bash

if [ ! -d /config/addons_config/unpackerr ]; then
    echo "Creating /config/addons_config/unpackerr"
    mkdir -p /config/addons_config/unpackerr
    echo "Updating files ownership"
    chown -R "$(id -u)":"$(id -g)" /config/addons_config/unpackerr
fi
