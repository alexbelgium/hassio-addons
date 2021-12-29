#!/usr/bin/with-contenv bashio

################
# Alternate UI #
################

if bashio::config.has_value 'theme'; then
  ### Variables
  CUSTOMUI=$(bashio::config 'theme')
  bashio::log.info "Alternate theme enabled : $CUSTOMUI. If webui don't work, disable this option"

  ### Download WebUI
  case $CUSTOMUI in
  "comixology2")
    curl -s -S -J -L -o /data/release.zip https://github.com/scooterpsu/Comixology_Ubooquity_2/releases/download/v3.4/comixology2.zip >/dev/null &&
      unzip -o -q /data/release.zip -d /config/addon_config/ubooquity/themes/
    ;;

  "plextheme-master")
    curl -s -S -J -L -o /data/release.zip https://github.com/FinalAngel/plextheme/archive/master.zip >/dev/null &&
      unzip -q /data/release.zip -d /config/addon_config/ubooquity/themes/
    #    && mv /config/addon_config/ubooquity/themes/plextheme-master/ /config/addon_config/ubooquity/themes/
    ;;

  esac

  ### Clean files
  rm /data/release.zip || true

  ### Set preference
  jq --arg variable $CUSTOMUI '.theme = $variable' /config/addon_config/ubooquity/preferences.json | sponge /config/addon_config/ubooquity/preferences.json

fi
