#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

LAUNCHER="sudo -u abc php /data/config/www/nextcloud/occ" || bashio::log.info "/data/config/www/nextcloud/occ not found"
if ! bashio::fs.file_exists '/data/config/www/nextcloud/occ'; then
    LAUNCHER=$(find / -name "occ" -print -quit)
fi || bashio::log.info "occ not found"

# Make sure there is an Nextcloud installation
if [[ $($LAUNCHER -V 2>&1) == *"not installed"* ]]; then
    bashio::log.warning "... it seems there is no Nextcloud server installed. Please restart the addon after initialization of the user."
    exit 0
fi

# Install specific packages
if [ ! -d /data/config/www/nextcloud/apps/pdfannotate ]; then
    CURRENT="$PWD"
    cd /data/config/www/nextcloud/apps || exit
    git clone https://gitlab.com/nextcloud-other/nextcloud-annotate pdfannotate
    cd "$CURRENT" || exit
    apk add --no-cache ghostscript >/dev/null
    echo "Nextcloud annotate app added to Nextcloud app store"
fi

# Install specific apps
if bashio::config.has_value 'additional_apps'; then
    bashio::log.info "Installing additional apps :"
    NEWAPPS="$(bashio::config 'additional_apps')"
    OIFS=$IFS
    IFS=","
    re='^( *).*'
    read -ra array <<< "$NEWAPPS"
    IFS=$OIFS
    for element in "${array[@]}"
    do
        if [[ $element =~ $re ]]; then
            # shellcheck disable=SC2295
            APP="${element#${BASH_REMATCH[1]}}"
            bashio::log.green "... $APP"
            # shellcheck disable=SC2015,SC2086
            apk add --no-cache $APP >/dev/null || bashio::log.red "... not successful, please check $APP package name"
        fi
    done
fi
