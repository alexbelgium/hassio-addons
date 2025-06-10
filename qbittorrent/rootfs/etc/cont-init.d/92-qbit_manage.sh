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
  # qBittorrent path to local
  echo "... default url set to 127.0.0.1, change manually if you have an external qbt system"
  sed -i "s/localhost/127.0.0.1/g" /config/qbit_manage/qbit_manage.yml
  # Set password from options
  echo "... setting username to the addon options one"
  sed -i "/user:/c\  user: '$(bashio::config 'Username')'" /config/qbit_manage/qbit_manage.yml
  # If password is default, correct
  echo "... default password set to homeassistant, change manually in the file if not"
  sed -i "/pass: password/c\  pass: homeassistant" /config/qbit_manage/qbit_manage.yml
  # Set root dir
  echo "... downloads directory set to $(bashio::config 'SavePath')"
  sed -i "/  root_dir/d" /config/qbit_manage/qbit_manage.yml
  sed -i "/directory:/a\  root_dir: \"$(bashio::config 'SavePath')\"" /config/qbit_manage/qbit_manage.yml

  # Startup delay 30s ; config file specific ; log file specific
  python /qbit_manage/qbit_manage.py -sd 30 --config-file "/config/qbit_manage/qbit_manage.yml" --log-file "/config/qbit_manage/qbit_manage.log" &
  true
  bashio::log.info "qbit_manage started with config in /addon_configs/$HOSTNAME/qbit_manage/qbit_manage.yaml accessible with the Filebrowser addon"

fi
