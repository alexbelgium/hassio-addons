#!/usr/bin/with-contenv bashio

# Define home
HOME="/share/webtop"
mkdir -p $HOME
chown -R abc:abc $HOME

# Create symlinks
#for FOLDERS in ".config" ".local" "Desktop" "Documents" "Downloads" "Music" "Pictures" "Public" "Templates" "Videos" "thinclient_drives"; do
#mkdir -p $HOME/$FOLDERS
#if [ -d /config/$FOLDERS ]; then
#  cp /config/$FOLDERS/* $HOME/$FOLDERS
#  rm -r /config/$FOLDERS
#fi
#ln -s $HOME/$FOLDERS /config
#done
