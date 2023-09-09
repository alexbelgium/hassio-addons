#!/bin/sh
# shellcheck disable=SC2015

##############################
# Automatic apps download #
##############################

PACKAGES="$1"

# Install bash if needed
if ! command -v bash >/dev/null 2>/dev/null; then
    (apt-get update && apt-get install -yqq --no-install-recommends bash || apk add --no-cache bash) >/dev/null
fi

# Install curl if needed
if ! command -v curl >/dev/null 2>/dev/null; then
    (apt-get update && apt-get install -yqq --no-install-recommends curl || apk add --no-cache curl) >/dev/null
fi

# Call apps installer script if needed
curl -f -L -s -S "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/automatic_packages.sh" --output /automatic_packages.sh
chmod 777 /automatic_packages.sh
eval /./automatic_packages.sh "${PACKAGES:-}"

# Clean
rm /automatic_packages.sh
