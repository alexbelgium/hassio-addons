#!/usr/bin/with-contenv bashio

###############
# DNS SETTING #
###############

printf "nameserver 8.8.8.8 1.1.1.1" > /etc/resolv.conf
chmod 644 /etc/resolv.conf
