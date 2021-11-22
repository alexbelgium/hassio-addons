#!/bin/bash
# If dockerfile failed install manually
if [ ! -f "/usr/bin/bashio" ]; then
    echo "Bashio does not exist, executing script"
    (
        ################
        # Install apps #
        ################
        apk add --no-cache \
            curl \
            jq \
            bash \
            cifs-utils \
            keyutils \
            samba \
            samba-client \
            bind-tools \
            nginx

        ###################
        # Install bashio #
        ##################
        BASHIO_VERSION=0.13.1
        mkdir -p /tmp/bashio
        curl -L -f -s "https://github.com/hassio-addons/bashio/archive/v${BASHIO_VERSION}.tar.gz" |
            tar -xzf - --strip 1 -C /tmp/bashio
        mv /tmp/bashio/lib /usr/lib/bashio
        ln -s /usr/lib/bashio/bashio /usr/bin/bashio
        rm -rf /tmp/bashio

        ########################################
        # Correct upstream image folders links #
        ########################################
        mkdir -p -m 777 /config/filebrowser || true

    ) >/dev/null
    echo "Bashio installed"
fi
