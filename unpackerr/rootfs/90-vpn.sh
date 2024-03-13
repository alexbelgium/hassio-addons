#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set +e

VPN_PROVIDER="${VPN_PROVIDER:-null}"
case "$VPN_PROVIDER" in
  "generic")
    echo "" > etc/s6*/s6*/service-pia/run
    echo "" > /etc/s6*/s6*/service-proton/run
  ;;

  "pia")
    echo "" > /etc/s6*/s6*/service-privoxy/run
    echo "" > /etc/s6*/s6*/service-proton/run
  ;;

  "proton")
    echo "" > /etc/s6*/s6*/service-privoxy/run
    echo "" > /etc/s6*/s6*/service-pia/run
  ;;

  **)
    echo "" > /etc/s6*/s6*/service-privoxy/run
    echo "" > /etc/s6*/s6*/service-proton/run
    echo "" > /etc/s6*/s6*/service-pia/run
  ;;
esac
