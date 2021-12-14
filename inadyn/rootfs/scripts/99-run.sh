#!/usr/bin/env bashio

#################
# Create config #
#################
mustache-cli /data/options.json /templates/inadyn.mustache >/etc/inadyn.conf

##############
# Launch App #
##############
/usr/sbin/inadyn --foreground
