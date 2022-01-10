#!/bin/bash
# If dockerfile failed install manually
if [ -e "/ENVFILE" ]; then
    echo "Executing script"
    PACKAGES=$(</ENVFILE)
    (
        #######################
        # Automatic installer #
        #######################
        if ! command -v bash >/dev/null 2>/dev/null; then (apt-get update && apt-get install -yqq --no-install-recommends bash || apk add --no-cache bash); fi && \
        $(curl --help &>/dev/null) || (apt-get update && apt-get install -yqq --no-install-recommends curl &>/dev/null || apk add --no-cache curl) && \
        curl -L -f -s "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/zzz_templates/automatic_packages.sh" --output /automatic_packages.sh && \
        chmod 777 /automatic_packages.sh && \
        eval /./automatic_packages.sh "$PACKAGES" && \
        rm /automatic_packages.sh

    ) >/dev/null

fi

if [ -e "/MODULESFILE" ]; then
    echo "Executing modules script"
    PACKAGES=$(</MODULESFILE)
    (
        ##############################
        # Automatic modules download #
        ##############################
        mkdir -p /tmpscripts /scripts /etc/cont-init.d && \
        for scripts in $MODULES; do curl -L -f -s "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/zzz_templates/$scripts" -o /tmpscripts/"$scripts"; done && \
        /bin/cp -rf /tmpscripts/* {/scripts/, /etc/cont-init.d/} && \
        chmod -R 777 {/scripts, /etc/cont-init.d} && \
        rm -rf /tmpscripts
    ) >/dev/null

fi
