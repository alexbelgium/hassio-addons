#!/bin/bash

if [ -f /etc/cont-init.d/00-smb_mounts.sh ]; then
    sed -i "s|cifs -o \"|cifs -o \"nobrl,|g" /etc/cont-init.d/00-smb_mounts.sh
fi
