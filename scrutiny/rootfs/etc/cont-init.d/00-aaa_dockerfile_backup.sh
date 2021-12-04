#!/bin/bash
# If dockerfile failed install manually
if [ ! -f "/usr/bin/bashio" ]; then
    echo "Bashio does not exist, executing script"
    (
        ################
        # Install apps #
        ################
        apk add --no-cache \
    jq \
    curl \
    cifs-utils \
    nginx 

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

        ###################
        # Install tempio #
        ##################
        curl -L -f -s -o /usr/bin/tempio \
    "https://github.com/home-assistant/tempio/releases/download/${TEMPIO_VERSION}/tempio_${BUILD_ARCH}" \
    && chmod a+x /usr/bin/tempio

    ) >/dev/null

fi
