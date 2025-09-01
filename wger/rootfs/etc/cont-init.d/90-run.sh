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
(
    set -o posix
    export -p
) > /data/env.sh
chown -R wger /data
chown -R wger /home/wger
chmod -R 777 /data

bashio::log.info "Starting nginx"
nginx || true &
true

bashio::log.info "Starting entrypoint"
