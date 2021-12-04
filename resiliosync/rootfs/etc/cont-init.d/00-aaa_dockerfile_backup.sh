#!/bin/bash

# If dockerfile failed install manually
if [ ! -f "/usr/bin/bashio" ]; then
    echo "Bashio does not exist, executing script"
    (
        ################
        # Install apps #
        ################
        apt-get clean \
            apt-get update \
            apt-get install -y --no-install-recommends \
            jq \
            curl \
            cifs-utils \
            keyutils \
            samba \
            smbclient

        ##################
        # Install bashio #
        ##################
        curl -J -L -o /tmp/bashio.tar.gz \
            "https://github.com/hassio-addons/bashio/archive/v${BASHIO_VERSION}.tar.gz" &&
            mkdir /tmp/bashio &&
            tar zxvf \
                /tmp/bashio.tar.gz \
                --strip 1 -C /tmp/bashio &&
            mv /tmp/bashio/lib /usr/lib/bashio &&
            ln -s /usr/lib/bashio/bashio /usr/bin/bashio &&
            rm -fr \
                /tmp/*

    ) >/dev/null

fi
