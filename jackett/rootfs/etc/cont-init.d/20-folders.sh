#!/bin/bash

if [ ! -d /share/Jackett ]; then
    echo "Creating /share/Jacket"
    mkdir /share/Jackett
    chown -R abc:abc /share/Jackett
fi

if [ -d /config/Jackett ] && [ ! -d /config/addons_config/Jackett ]; then
    echo "Moving to new location /config/addons_config/Jackett"
    mkdir /config/addons_config/Jackett
    chown -R abc:abc /config/addons_config/Jackett
    mv /config/Jackett/* /config/addons_config/Jackett/
    rm -r /config/Jackett
    rm -r /config/jackett
fi

if [ ! -d /config/addons_config/Jackett ]; then
    echo "Creating /config/addons_config/Jackett"
    mkdir /config/addons_config/Jackett
    chown -R abc:abc /config/addons_config/Jackett
fi
