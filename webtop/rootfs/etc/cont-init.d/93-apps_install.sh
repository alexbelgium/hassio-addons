#!/usr/bin/with-contenv bashio

if bashio::config.has_value 'additional_apps'; then
    bashio::log.info "Installing additional apps :" 
    apt-get update &>/dev/null
    # Install apps
            for APP in $(echo "$(bashio::config 'additional_apps')" | tr "," " "); do
              bashio::log.green "... $APP"
              apt-get install -yqq $APP &>/dev/null \
              && bashio::log.green "... done" \
              || bashio::log.red "... not successful"
            done
fi
