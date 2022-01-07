#!/bin/bash

mkdir -p /share/webtop-alpine
chown abc:abc /share/webtop-alpine
if [ ! -f /config/configuration.html ]; then
rm -r /config
fi
ln -s /share/webtop-alpine /config
