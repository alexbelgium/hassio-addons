#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Define home
HOME="/share/webtop_kde"
mkdir -p $HOME
chown -R abc:abc $HOME
chmod -R 755 $HOME

#adduser USERNAME
#useradd -m abc -p abc
