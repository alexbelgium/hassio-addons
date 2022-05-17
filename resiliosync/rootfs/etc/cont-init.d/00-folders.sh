#!/bin/bash

echo "Checking folders"
LOCATION="/share/resiliosync"
mkdir -p "$LOCATION"/folders
mkdir -p "$LOCATION"/mounted_folders
mkdir -p /share/resiliosync_config

echo "Checking permissions"
chown -R "$(id -u):$(id -g)" "$LOCATION"
