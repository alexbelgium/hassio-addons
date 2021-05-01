#!/usr/bin/with-contenv bashio

###############
# DNS SETTING #
###############

DNS="# Avoid usage of local dns such as adguard home or pihole\n"
DNS="${DNS}nameserver 8.8.8.8\n"
DNS="${DNS}nameserver 1.1.1.1"
printf "${DNS}" > /etc/resolv.conf
chmod 644 /etc/resolv.conf

