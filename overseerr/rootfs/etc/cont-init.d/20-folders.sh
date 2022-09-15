#!/bin/bash

if [ ! -d /config/addons_config/overseerr ]; then
    echo "Creating /config/addons_config/overseerr"
    mkdir -p /config/addons_config/overseerr
fi

if [ -d /config/addons_config/addons_config/overseerr ]; then
    echo "Migrating data to /config/addons_config/overseerr"
    mv /config/addons_config/addons_config/overseerr /config/addons_config/overseerr
fi

chown -R abc:abc /config/addons_config/overseerr
chown -R abc:abc /config/.config/yarn
chmod -R 777 /config/.config/yarn
