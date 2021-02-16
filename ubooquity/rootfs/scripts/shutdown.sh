#!/bin/sh
# Shutdown addon

s6-svscanctl -t /var/run/s6/services
