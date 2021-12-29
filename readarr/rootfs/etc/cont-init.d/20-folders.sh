#!/usr/bin/with-contenv bashio

if [ ! -d /share/music ]; then
  echo "Creating /share/music"
  mkdir -p /share/music
  chown -R abc:abc /share/music
fi

if [ ! -d /share/downloads ]; then
  echo "Creating /share/downloads"
  mkdir -p /share/downloads
  chown -R abc:abc /share/downloads
fi

if [ -d /config/readarr ]; then
  echo "Moving to new location /config/addons_config/readarr"
  mkdir -p /config/addons_config/readarr
  chown -R abc:abc /config/addons_config/readarr
  mv /config/readarr/* /config/addons_config/readarr/
  rm -r /config/readarr
fi

if [ ! -d /config/addons_config/readarr ]; then
  echo "Creating /config/addons_config/readarr"
  mkdir -p /config/addons_config/readarr
  chown -R abc:abc /config/addons_config/readarr
fi
