#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set +e

VPN_PROVIDER="${VPN_PROVIDER:-null}"
case "$VPN_PROVIDER" in
  "generic")
    rm -r /etc/s6*/s6*/service-pia
    rm -r /etc/s6*/s6*/service-proton  
  ;;

  "pia")
    rm -r /etc/s6*/s6*/service-privoxy
    rm -r /etc/s6*/s6*/service-proton  
  ;;

  "proton")
    rm -r /etc/s6*/s6*/service-privoxy
    rm -r /etc/s6*/s6*/service-pia
  ;;

  **)
    rm -r /etc/s6*/s6*/service-privoxy
    rm -r /etc/s6*/s6*/service-proton  
    rm -r /etc/s6*/s6*/service-pia
  ;;
esac
