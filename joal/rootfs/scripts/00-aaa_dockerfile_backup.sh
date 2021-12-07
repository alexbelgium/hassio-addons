#!/bin/bash
# If dockerfile failed install manually
if [ ! -f "/usr/bin/bashio" ]; then
    echo "Bashio does not exist, executing script"
    (
        ################
        # Install apps #
        ################
        PACKAGES="${PACKAGES:="curl"}"
        
        apt-get clean \
        && apt-get update \
        && apt-get install -y --no-install-recommends ${PACKAGES} 2>/dev/null \
        || apk add --no-cache ${PACKAGES}

        ###################
        # Install bashio #
        ##################
        
        mkdir -p /tmp/bashio
        curl -L -f -s "https://github.com/hassio-addons/bashio/archive/v${BASHIO_VERSION}.tar.gz" |
            tar -xzf - --strip 1 -C /tmp/bashio
        mv /tmp/bashio/lib /usr/lib/bashio
        ln -s /usr/lib/bashio/bashio /usr/bin/bashio
        rm -rf /tmp/bashio

    ) >/dev/null

fi
