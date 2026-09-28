#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

CONFIGSOURCE="/config/configurations"

# Create directory
mkdir -p "$CONFIGSOURCE"

# The app reads data/configurations; -n replaces the link kept in /data instead of nesting a new one inside it
ln -sfn "$CONFIGSOURCE" /data/configurations

# Make sure permissions are right
chown -R "$(id -u):$(id -g)" "$CONFIGSOURCE"
