#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# wait until vpn is up
sleep 5

# test if vpn is up
counter=0
until [ "$counter" -gt 5 ]
do
  ping -c 1 1.1.1.1 &> /dev/null && break || true
  ((counter++))
  sleep 5
done
