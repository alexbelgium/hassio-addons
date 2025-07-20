#!/bin/bash

for files in /etc/services.d/*; do
    if [[ -f /etc/services.d/$files/run ]]; then
        echo "Starting $files"
        chmod +x /etc/services.d/$files/run
        /./etc/services.d/$files/run & sleep 10
    fi
done
