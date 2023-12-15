#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# wait until vpn is up
sleep 5

# test if vpn is up
counter=0
until [ "$counter" -gt 10 ]
do
  echo "... waiting until vpn is up"
  ping -c 1 "1.1.1.1" &> /dev/null && exit 0 || true
  ((counter++))
  sleep 5
done

bashio::log.fatal "vpn failed to get up for 60 seconds. Issue with your config file ?"

if [ ! -d /REBOOT ]; then
  touch /REBOOT
  bashio::addon.restart
fi
