#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

if bashio::config.true "qbit_manage"; then

    bashio::log.info "qbit_manage activated, setting system"

    # Set folder
    echo "... setting folder"
    mkdir -p /config/qbit_manage
    chmod -R 777 /config/qbit_manage

    # Create default file
    if [ ! -f /config/qbit_manage/qbit_manage.yml ]; then
        echo "... create default file"
        cp /qbit_manage/config/config.yml.sample /config/qbit_manage/qbit_manage.yml
    fi

    # Set qBittorrent options
    echo "... align QBT username and password"
    sed -i "/host:/c\  host: \"localhost:8080\"" /config/qbit_manage/qbit_manage.yml
    sed -i "/user:/c\  user: \"$(bashio::config "QBT_USERNAME")\"" /config/qbit_manage/qbit_manage.yml
    sed -i "s=root_dir: \"/data/torrents/\"=$(bashio::config.has_value "SavePath")=g" /config/qbit_manage/qbit_manage.yml
    sed -i "s=remote_dir: \"/mnt/user/data/torrents/\"=$(bashio::config.has_value "SavePath")=g" /config/qbit_manage/qbit_manage.yml

    # Startup delay 30s ; config file specific ; log file specific
    python /qbit_manage/qbit_manage.py -sd 30 --config-file "/config/qbit_manage/qbit_manage.yml" --log-file "/config/qbit_manage/qbit_manage.log" --run & true
    bashio::log.info "qbit_manage started with config in /addon_configs/$HOSTNAME/qbit_manage/qbit_manage.yaml accessible with the Filebrowser addon"

fi
