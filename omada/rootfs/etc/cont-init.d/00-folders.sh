#!/bin/bash
# shellcheck shell=bash
set -e

CONFIGSOURCE="/data"

# Use ssl
if [ -d /ssl ]; then
    mkdir -p /cert
    cp -r /ssl/* /cert
    chown -R 508:508 /cert
fi

# Create directory
if [ ! -f "$CONFIGSOURCE" ]; then
    echo "Creating directory"
    mkdir -p "$CONFIGSOURCE"
fi

# Ensure structure is correct
cp -rnf /opt/tplink/EAPController/data/* "$CONFIGSOURCE"

echo "Creating symlink"
# Clean existing folder
rm -r /opt/tplink/EAPController/data/*

# Create symlinks for all files in /data
# shellcheck disable=SC2086
for folders in html keystore pdf db omada/html portal; do
    # Create new folder
    mkdir -p /data/"$folders"
    # Remove previous one
    if [ -d /opt/tplink/EAPController/data/"$folders" ]; then 
        cp -rnf /opt/tplink/EAPController/data/"$folders"/* /data/"$folders"/* 2>/dev/null || true
        rm -r /opt/tplink/EAPController/data/"$folders"
    fi
    # Create symlink
    ln -s /data/"$folders" /opt/tplink/EAPController/data || true
done

touch /data/LAST_RAN_OMADA_VER.txt
if [ -f /opt/tplink/EAPController/data/LAST_RAN_OMADA_VER.txt ]; then rm /opt/tplink/EAPController/data/LAST_RAN_OMADA_VER.txt; fi
ln -s /data/LAST_RAN_OMADA_VER.txt /opt/tplink/EAPController/data/

# Make sure permissions are right
echo "Updating permissions"
chmod -R 777 "$CONFIGSOURCE"
chown -R "omada:omada" "$CONFIGSOURCE"

bashio::log.warning ""
bashio::log.warning ""
bashio::log.warning "Recommendation : please backup your database and migrated to this addon https://github.com/jkunczik/home-assistant-omada"
bashio::log.warning ""
bashio::log.warning ""
