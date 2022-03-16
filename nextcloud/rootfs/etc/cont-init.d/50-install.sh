#!/bin/bash

# create folders
mkdir -p \
    "${NEXTCLOUD_PATH}" \
    /data/config/crontabs

# install app
if [ ! -e "${NEXTCLOUD_PATH}/index.php" ]; then
    tar xf /app/nextcloud.tar.bz2 -C \
        "${NEXTCLOUD_PATH}" --strip-components=1
    chown abc:abc -R \
        "${NEXTCLOUD_PATH}"
    chmod +x "${NEXTCLOUD_PATH}/occ"
fi

#?set cronjob
[[ ! -f /data/config/crontabs/root ]] && \
    cp /defaults/root /data/config/crontabs/root
cp /data/config/crontabs/root /etc/crontabs/root
