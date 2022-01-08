#!/usr/bin/with-contenv bashio

HOME="/share/webtop"
mkdir -p $HOME
chown -R abc:abc $HOME
cp -rn /config/* $HOME/
bashio::log.info "Your files are located in $HOME"

#for FOLDERS in "Desktop" "thinclient_drives" ".config"; do
#mkdir -p /share/webtop-alpine/$FOLDERS
#if [ -d /config/$FOLDERS ]; then
#  cp /config/$FOLDERS/* /share/webtop-alpine/$FOLDERS
#  rm -r /config/$FOLDERS
#fi
#ln -s /share/webtop-alpine/$FOLDERS /config
#done
