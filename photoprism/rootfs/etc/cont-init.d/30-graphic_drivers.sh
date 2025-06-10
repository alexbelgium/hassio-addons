#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2015
set -e

if bashio::config.has_value 'graphic_drivers'; then
    GRAPHIC_DRIVERS="$(bashio::config 'graphic_drivers')"
    bashio::log.info "Installing selected graphic drivers : $GRAPHIC_DRIVERS..."

    ### Download WebUI
    case "$GRAPHIC_DRIVERS" in

        "mesa")
            apt-get update
            apt-get install -yqq -- *mesa* >/dev/null
            echo "... done"
            ;;

        "nvidia")
            apt-get update
            apt-get install -yqq -- *nvidia* >/dev/null
            echo "... done"
            ;;

        "radeon")
            apt-get update
            apt-get install -yqq -- *radeon* >/dev/null
            echo "... done"
            ;;

        *)
            echo "... no drivers selected"
            ;;

  esac
fi
