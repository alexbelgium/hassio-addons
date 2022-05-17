#!/bin/bash

echo "Checking folders"
PATH="/share/resiliosync"
mkdir -p "$PATH"/folders
mkdir -p "$PATH"/mounted_folders

echo "Checking permissions"
chown -R "$(id -u):$(id -g)" "$PATH"
