#!/bin/bash
# If dockerfile failed install manually
if -f "/ENVFILE" ; then
    echo "Executing script"
    PACKAGES=$(cat /ENVFILE)
    rm /ENVFILE
    (
        #######################
        # Automatic installer #
        #######################
        $(ls /bin/bash &>/dev/null) || (apt-get install -y --no-install-recommends bash || apk add --no-cache bash) && \
        $(curl --help &>/dev/null) || (apt-get install -y --no-install-recommends curl &>/dev/null || apk add --no-cache curl) && \
        curl -L -f -s "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/zzz_templates/automatic_packages.sh" --output /automatic_packages.sh  && \
        chmod 777 /automatic_packages.sh && \
        eval /./automatic_packages.sh "$PACKAGES" && \
        rm /automatic_packages.sh

    ) >/dev/null

fi
