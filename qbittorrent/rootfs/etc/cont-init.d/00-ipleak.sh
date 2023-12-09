#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

curl --max-time 10 --connect-timeout 5 -s ipecho.net/plain > /currentip