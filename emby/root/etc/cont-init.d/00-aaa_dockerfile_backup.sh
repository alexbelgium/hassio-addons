#!/bin/bash
# If dockerfile failed install manually
if [ ! -f "/usr/bin/bashio" ]; then
    echo "Bashio does not exist, executing script"
    (
        ################
        # Install apps #
        ################
        cd /
        curl -L -f -s "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/zzz_templates/automatic_packages.sh" --output automatic_packages.sh
        chmod 777 automatic_packages.sh
        $(./automatic_packages.sh)

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
