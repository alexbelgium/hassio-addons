#!/usr/bin/env bashio

############################
# Change database location #
############################
echo "... set database path"
sed -i "s|/home/wger/db/database.sqlite|/data/database.sqlite|g" /home/wger/src/settings.py

#####################
# Adapt directories #
#####################
echo "... create directories"
mkdir -p /data/static
if [ -d /home/wger/static ]; then
    if [ -n "$(ls -A /home/wger/static 2> /dev/null)" ]; then
        cp -rnf /home/wger/static/* /data/static/
    fi
    rm -r /home/wger/static
fi
ln -s /data/static /home/wger

mkdir -p /data/media
if [ -d /home/wger/media ]; then
    if [ -n "$(ls -A /home/wger/media 2> /dev/null)" ]; then
        cp -rnf /home/wger/media/* /data/media/
    fi
    rm -r /home/wger/media
fi
ln -s /data/media /home/wger

#####################
# Align permissions #
#####################
echo "... align permissions"
chown -R wger /data
chown -R wger /home/wger
chmod -R 777 /data

echo "... add env variables"
(
    set -o posix
    export -p
) > /data/env.sh
while IFS= read -r line; do
  [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
  var="${line%%=*}"
  sed -i "/^export[[:space:]]\+$var=/d" /data/env.sh
  echo "export $line" >> /data/env.sh
done < /.env

chown wger /data/env.sh
chmod +x /data/env.sh

bashio::log.info "Starting nginx"
nginx || true &
true

bashio::log.info "Starting entrypoint"
