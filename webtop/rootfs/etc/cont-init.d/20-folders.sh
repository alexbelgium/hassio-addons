#!/bin/bash

mkdir -p /share/webtop-alpine
chown abc:abc /share/webtop-alpine
if [ ! -f /config/configuration.yaml ]; then
  rm -r /config
ln -s /share/webtop-alpine /config
echo "Data folder set to /share/webtop-alpine"
fi
