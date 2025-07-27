#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

#################
# Create config #
#################
mustache-cli /data/options.json /templates/inadyn.mustache > /etc/inadyn.conf

# Check it
/usr/sbin/inadyn --check-config

##############
# Launch App #
##############
/usr/sbin/inadyn --foreground --force
