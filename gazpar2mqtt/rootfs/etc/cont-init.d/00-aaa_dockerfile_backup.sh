#!/bin/bash

# If dockerfile failed install manually

##############################
# Automatic modules download #
##############################
if [ -e "/MODULESFILE" ]; then
    MODULES=$(</MODULESFILE)
    MODULES="${MODULES:-00-banner.sh}"
    echo "Installing modules : $MODULES" 

    if ! command -v bash >/dev/null 2>/dev/null; then (apt-get update && apt-get install -yqq --no-install-recommends bash || apk add --no-cache bash) >/dev/null; fi && \
    if ! command -v curl >/dev/null 2>/dev/null; then (apt-get update && apt-get install -yqq --no-install-recommends curl || apk add --no-cache curl) >/dev/null; fi && \
    mkdir -p /etc/cont-init.d && \
    for scripts in $MODULES; do curl -L -f -s -S "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/$scripts" -o /etc/cont-init.d/$scripts || echo "script failed to install $scripts"; done && \
    chmod -R 777 /etc/cont-init.d || printf '%s\n' "${MODULES}" >/MODULESFILE
fi

#######################
# Automatic installer #
#######################
if [ -e "/ENVFILE" ]; then
    PACKAGES=$(</ENVFILE)
    echo "Installing apps : $PACKAGES" 

    if ! command -v bash >/dev/null 2>/dev/null; then (apt-get update && apt-get install -yqq --no-install-recommends bash || apk add --no-cache bash) >/dev/null; fi && \
    if ! command -v curl >/dev/null 2>/dev/null; then (apt-get update && apt-get install -yqq --no-install-recommends curl || apk add --no-cache curl) >/dev/null; fi && \
    curl -L -f -s "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/automatic_packages.sh" --output /automatic_packages.sh && \
    chmod 777 /automatic_packages.sh && \
    eval /./automatic_packages.sh "$PACKAGES" && \
    rm /automatic_packages.sh
fi
