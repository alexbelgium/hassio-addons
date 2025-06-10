#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

################
# Alternate UI #
################

if bashio::config.has_value 'theme'; then
    ### Variables
    CUSTOMUI=$(bashio::config 'theme')
    bashio::log.info "Alternate theme enabled : $CUSTOMUI. If webui don't work, disable this option"

    ### Download WebUI
    case "$CUSTOMUI" in
        "comixology2")
            curl -f -s -S -J -L -o /data/release.zip https://github.com/scooterpsu/Comixology_Ubooquity_2/releases/download/v3.4/comixology2.zip >/dev/null &&
            unzip -o -q /data/release.zip -d /config/addons_config/ubooquity/themes/
            ;;

        "plextheme-master")
            curl -f -s -S -J -L -o /data/release.zip https://github.com/FinalAngel/plextheme/archive/master.zip >/dev/null &&
            unzip -q /data/release.zip -d /config/addons_config/ubooquity/themes/
            #    && mv /config/addons_config/ubooquity/themes/plextheme-master/ /config/addons_config/ubooquity/themes/
            ;;

        "default")
            exit 0
            ;;

  esac

    ### Clean files
    rm /data/release.zip || true

    ### Set preference
    jq --arg variable "$CUSTOMUI" '.theme = $variable' /config/addons_config/ubooquity/preferences.json | sponge /config/addons_config/ubooquity/preferences.json

fi
