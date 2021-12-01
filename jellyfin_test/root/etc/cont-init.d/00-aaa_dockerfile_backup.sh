#!/bin/bash
# If dockerfile failed install manually
if [ ! -f "/usr/bin/bashio" ]; then
    echo "Bashio does not exist, executing script"
    (
        ################
        # Install apps #
        ################
        apt-get update
        apt-get install -y --no-install-recommends \
        jq \
        yq \
        samba \
        smbclient \
        nginx
        apt-get -y upgrade cifs-utils

        # Allow UID and GID setting
        sed -i 's/bash/bashio/g' /etc/cont-init.d/10-adduser
        sed -i 's/{PUID:-911}/(bashio::config "PUID")/g' /etc/cont-init.d/10-adduser
        sed -i 's/{PGID:-911}/(bashio::config "PGID")/g' /etc/cont-init.d/10-adduser
        sed -i "s|/config|/config/jellyfin|g" /etc/services.d/jellyfin/run
        sed -i "s|/config|/config/jellyfin|g" /etc/cont-init.d/10-adduser
        sed -i "s|/config|/config/jellyfin|g" /etc/cont-init.d/30-config

        ###################
        # Install bashio #
        ##################
        BASHIO_VERSION=0.14.3
        mkdir -p /tmp/bashio
        curl -L -f -s "https://github.com/hassio-addons/bashio/archive/v${BASHIO_VERSION}.tar.gz" |
            tar -xzf - --strip 1 -C /tmp/bashio
        mv /tmp/bashio/lib /usr/lib/bashio
        ln -s /usr/lib/bashio/bashio /usr/bin/bashio
        rm -rf /tmp/bashio
    ) >/dev/null

fi
