#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

CONFIGSOURCE="/config/addons_config/fireflyiii_fints_importer"

# Create directory
mkdir -p "$CONFIGSOURCE"

# Remove the self-referencing link created by previous versions
if [ -L "$CONFIGSOURCE/fireflyiii_fints_importer" ]; then
    rm "$CONFIGSOURCE/fireflyiii_fints_importer"
fi

# The app reads data/configurations; -n replaces the link kept in /data instead of nesting a new one inside it
ln -sfn "$CONFIGSOURCE" /data/configurations

# Make sure permissions are right
chown -R "$(id -u):$(id -g)" "$CONFIGSOURCE"
