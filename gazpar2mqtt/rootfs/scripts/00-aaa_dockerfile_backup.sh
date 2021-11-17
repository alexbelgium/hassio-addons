#!/bin/bash
# If dockerfile failed install manually 
[ ! -f "/usr/bin/bashio" ]; then
    echo "Bashio does not exist, executing script"

    ################
    # Install apps #
    ################
    apt-get clean &&
        apt-get update &&
        apt-get install -y --no-install-recommends \
            jq \
            curl \
            yamllint

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

    echo "Bashio installed"
fi
