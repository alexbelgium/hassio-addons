#!/bin/bash

# Avoid linuxserver anti tamper issues
chown root:root /config/custom-cont-init.d* &>/dev/null || true
chown root:root /config/custom-services* &>/dev/null || true
