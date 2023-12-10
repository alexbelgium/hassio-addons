#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

curl --max-time 10 --connect-timeout 5 -s https://ipecho.net/plain > /currentip
