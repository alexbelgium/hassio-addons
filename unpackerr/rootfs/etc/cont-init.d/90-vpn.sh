#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set +e

VPN_PROVIDER="${VPN_PROVIDER:-null}"
case "$VPN_PROVIDER" in
    "generic")
        sed -i "1a sleep infinity" etc/s6*/s6*/service-pia/run
        sed -i "1a sleep infinity" etc/s6*/s6*/service-proton/run
        ;;

    "pia")
        sed -i "1a sleep infinity" /etc/s6*/s6*/service-privoxy/run
        sed -i "1a sleep infinity" /etc/s6*/s6*/service-proton/run
        ;;

    "proton")
        sed -i "1a sleep infinity" /etc/s6*/s6*/service-privoxy/run
        sed -i "1a sleep infinity" /etc/s6*/s6*/service-pia/run
        ;;

    **)
        sed -i "1a sleep infinity" /etc/s6*/s6*/service-privoxy/run
        sed -i "1a sleep infinity" /etc/s6*/s6*/service-proton/run
        sed -i "1a sleep infinity" /etc/s6*/s6*/service-pia/run
        ;;
esac
