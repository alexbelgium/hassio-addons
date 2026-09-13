#!/bin/bash

if [ ! -d /config/addons_config/overseerr ]; then
    echo "Creating /config/addons_config/overseerr"
    mkdir -p /config/addons_config/overseerr
fi

if [ -d /config/addons_config/addons_config/overseerr ]; then
    echo "Migrating data to /config/addons_config/overseerr"
    mv /config/addons_config/addons_config/overseerr /config/addons_config/overseerr
fi

# shellcheck disable=SC2013
for file in $(grep -Esril "/config/.config/yarn" /usr /etc /defaults); do
    sed -i "s=/config/.config/yarn=/config/addons_config/overseerr/yarn=g" "$file"
done
yarn config set global-folder /config/addons_config/overseerr/yarn
chown -R "$PUID:$PGID" /config/addons_config/overseerr
