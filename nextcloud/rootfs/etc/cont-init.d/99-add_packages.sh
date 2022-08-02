#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

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
    IFS=","
    re='^( *).*'
    read -ra array <<< "$NEWAPPS"
    for element in "${array[@]}"
    do
        APP="${element#${BASH_REMATCH[1]}}"
        [[ $element =~ $re ]] && \
        bashio::log.green "... $APP" && \
        apk add --no-cache "$APP" || bashio::log.red "... not successful, please check $APP package name"
    done
fi
