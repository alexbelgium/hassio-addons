#!/bin/bash

if [ ! -d /data/config/www/nextcloud/apps/pdfannotate ]; then
    CURRENT="$PWD"
    cd /data/config/www/nextcloud/apps || exit
    git clone https://gitlab.com/nextcloud-other/nextcloud-annotate pdfannotate
    cd "$CURRENT" || exit
    apk add --no-cache ghostscript >/dev/null
    echo "Nextcloud annotate app added to Nextcloud app store"
fi
