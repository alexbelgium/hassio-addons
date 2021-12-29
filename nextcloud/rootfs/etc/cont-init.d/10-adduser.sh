#!/usr/bin/with-contenv bashio

PUID=$(bashio::config "PUID")
PGID=$(bashio::config "PGID")

groupmod -o -g "$PGID" abc
usermod -o -u "$PUID" abc
mkdir -p /data/config
mkdir -p /share/nextcloud
echo '
-------------------------------------
          _         ()
         | |  ___   _    __
         | | / __| | |  /  \
         | | \__ \ | | | () |
         |_| |___/ |_|  \__/


Brought to you by linuxserver.io
-------------------------------------'
if [[ -f /donate.txt ]]; then
    echo '
To support the app dev(s) visit:'
    cat /donate.txt
fi
echo '
To support LSIO projects visit:
https://www.linuxserver.io/donate/
-------------------------------------
GID/UID
-------------------------------------'
echo "
User uid:    $(id -u abc)
User gid:    $(id -g abc)
-------------------------------------
"
chown abc:abc /app
chown abc:abc /data/config
chown abc:abc /defaults

rm /config/nginx/site-confs/default 2>/dev/null || true
