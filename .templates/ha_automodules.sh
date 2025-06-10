#!/bin/sh
# shellcheck disable=SC2015
set -e

##############################
# Automatic modules download #
##############################

MODULES="$1"
MODULES="$MODULES 00-banner.sh 01-custom_script.sh 01-config_yaml.sh 00-global_var.sh"
echo "To download : $MODULES"

# Install bash if not available
if ! command -v bash > /dev/null 2> /dev/null; then
    (apt-get update && apt-get install -yqq --no-install-recommends bash || apk add --no-cache bash) > /dev/null
fi

# Install curl if not available
if ! command -v curl > /dev/null 2> /dev/null; then
    (apt-get update && apt-get install -yqq --no-install-recommends curl || apk add --no-cache curl) > /dev/null
fi

# Install ca-certificates if not available
apt-get update && apt-get install -yqq --no-install-recommends ca-certificates || apk add --no-cache ca-certificates > /dev/null || true

# Create folder for scripts
mkdir -p /etc/cont-init.d

# Download scripts
for scripts in $MODULES; do
    echo "$scripts" && curl -f -L -s -S "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/$scripts" -o /etc/cont-init.d/"$scripts" \
                                                                                                                                                                && [ "$(sed -n '/\/bin/p;q' /etc/cont-init.d/"$scripts")" != "" ] \
                                                                   || (echo "script failed to install $scripts" && exit 1)
done

chmod -R 755 /etc/cont-init.d
