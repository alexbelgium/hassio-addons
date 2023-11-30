#!/bin/bash
# shellcheck shell=bash
set -e

CONFIGSOURCE="/config"

# Use ssl
if [ -d /ssl ]; then
    mkdir -p /cert
    cp -r /ssl/* /cert
    chown -R 508:508 /cert
fi

# Migrate previous files
mkdir -p /config/data
mv /data/* /config/data

# Copy app files
cp -rnf /opt/tplink/EAPController/data/* /config/data/ 2>/dev/null || true
rm -r /opt/tplink/EAPController/data 2>/dev/null || true
rm -r /opt/tplink/EAPController/logs 2>/dev/null || true
mv /opt/tplink/EAPController/* /config

# Make sure permissions are right
echo "Updating permissions"
chmod -R 777 /config
chown -R "508:508" /config

echo ""
echo ""
echo "Recommendation : please backup your database and migrate to this addon https://github.com/jkunczik/home-assistant-omada"
echo ""
echo ""
