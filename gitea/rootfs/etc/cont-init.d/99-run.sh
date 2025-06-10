#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

for file in /data/gitea/conf/app.ini /etc/templates/app.ini; do

    if [ ! -f "$file" ]; then
        continue
  fi

    ##############
    # SSL CONFIG #
    ##############

    # Clean values
    sed -i "/PROTOCOL/d" "$file"
    sed -i "/CERT_FILE/d" "$file"
    sed -i "/KEY_FILE/d" "$file"

    # Add ssl
    bashio::config.require.ssl
    if bashio::config.true 'ssl'; then
        PROTOCOL=https
        bashio::log.info "ssl is enabled"
        sed -i "/server/a PROTOCOL=https" "$file"
        sed -i "/server/a CERT_FILE=/ssl/$(bashio::config 'certfile')" "$file"
        sed -i "/server/a KEY_FILE=/ssl/$(bashio::config 'keyfile')" "$file"
        chmod 744 /ssl/*
  else
        PROTOCOL=http
        sed -i "/server/a PROTOCOL=http" "$file"
  fi

    ##################
    # ADAPT ROOT_URL #
    ##################

    if bashio::config.has_value 'ROOT_URL'; then
        bashio::log.blue "ROOT_URL set, using value : $(bashio::config 'ROOT_URL')"
  else
        ROOT_URL="$PROTOCOL://$(bashio::config 'DOMAIN'):$(bashio::addon.port 3000)"
        bashio::log.blue "ROOT_URL not set, using extrapolated value : $ROOT_URL"
        sed -i "/server/a ROOT_URL=$ROOT_URL" "$file"
  fi

    ####################
    # ADAPT PARAMETERS #
    ####################

    for param in APP_NAME DOMAIN ROOT_URL; do
        # Remove parameter
        sed -i "/$param/d" "$file"

        # Define parameter
        if bashio::config.has_value "$param"; then
            echo "parameter set : $param=$(bashio::config "$param")"
            sed -i "/server/a $param = \"$(bashio::config "$param")\"" "$file"

            # Allow at setup
            sed -i "1a $param=\"$(bashio::config "$param")\"" /etc/s6/gitea/setup

    fi

  done

done

##############
# LAUNCH APP #
##############

bashio::log.info "Please wait while the app is loading !"

/./usr/bin/entrypoint
