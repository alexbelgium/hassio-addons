#!/bin/bash

for FOLDERS in "Desktop" "thinclient_drives" ".config"; do
mkdir -p /share/webtop-alpine/$FOLDERS
if [ -d /config/$FOLDERS ]; then
  cp /config/$FOLDERS/* /share/webtop-alpine/$FOLDERS
  rm -r /config/$FOLDERS
fi
ln -s /share/webtop-alpine/$FOLDERS /config
done

echo "Data folder set to /share/webtop-alpine"
chown -R abc:abc /share/webtop-alpine
