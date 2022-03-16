#!/bin/bash

# If dockerfile failed install manually

##############################
# Automatic modules download #
##############################
if [ -e "/MODULESFILE" ]; then
    MODULES=$(</MODULESFILE)
    MODULES="${MODULES:-00-banner.sh}"
    echo "Executing modules script : $MODULES"

    if ! command -v bash >/dev/null 2>/dev/null; then (apt-get update && apt-get install -yqq --no-install-recommends bash || apk add --no-cache bash) >/dev/null; fi \
        && if ! command -v curl >/dev/null 2>/dev/null; then (apt-get update && apt-get install -yqq --no-install-recommends curl || apk add --no-cache curl) >/dev/null; fi \
        && mkdir -p /etc/cont-init.d \
        && for scripts in $MODULES; do echo "$scripts" && curl -f -L -s -S "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/$scripts" -o /etc/cont-init.d/"$scripts" && [ "$(sed -n '/\/bin/p;q' /etc/cont-init.d/"$scripts")" != "" ] || (echo "script failed to install $scripts" && exit 1); done \
        && chmod -R 755 /etc/cont-init.d
fi

#######################
# Automatic installer #
#######################
if [ -e "/ENVFILE" ]; then
    PACKAGES=$(</ENVFILE)
    echo "Executing dependency script with custom elements : $PACKAGES"

    if ! command -v bash >/dev/null 2>/dev/null; then (apt-get update && apt-get install -yqq --no-install-recommends bash || apk add --no-cache bash) >/dev/null; fi \
        && if ! command -v curl >/dev/null 2>/dev/null; then (apt-get update && apt-get install -yqq --no-install-recommends curl || apk add --no-cache curl) >/dev/null; fi \
        && curl -f -L -s -S "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/automatic_packages.sh" --output /automatic_packages.sh \
        && chmod 777 /automatic_packages.sh \
        && eval /./automatic_packages.sh "${PACKAGES:-}" \
        && rm /automatic_packages.sh
fi
