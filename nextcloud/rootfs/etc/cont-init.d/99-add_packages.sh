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
    # hadolint ignore=SC2005
    NEWAPPS=$(bashio::config 'additional_apps')
    for APP in ${NEWAPPS//,/ }; do
        bashio::log.green "... $APP"
        # shellcheck disable=SC2015
        apk add --no-cache "$APP" >/dev/null || bashio::log.red "... not successful, please check package name"
    done
fi
