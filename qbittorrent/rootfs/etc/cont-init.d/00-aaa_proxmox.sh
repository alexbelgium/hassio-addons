#!/usr/bin/with-contenv bashio

TZ=$(bashio::config "TZ")
if [ $TZ = "test" ]; then
  echo "secret mode found..."
  echo "... launching script in /config/test.sh"
  if [ -f /config/test.sh ]; then
    cd /config
    chmod 777 test.sh
    ./test.sh
  fi
  echo "... launching specific test"
  cat /etc/hosts
fi
