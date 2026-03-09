#!/usr/bin/env bashio

############################
# Change database location #
############################
echo "... set database path"
mapfile -t SETTINGS_FILES < <(grep -rl --include='settings.py' '/home/wger/db/database.sqlite' /home 2> /dev/null || true)

if [ "${#SETTINGS_FILES[@]}" -gt 0 ]; then
    for settings_file in "${SETTINGS_FILES[@]}"; do
        sed -i "s|/home/wger/db/database.sqlite|/data/database.sqlite|g" "$settings_file"
    done
else
    bashio::log.warning "Unable to find settings.py containing database path under /home, skipping rewrite"
fi

#####################
# Adapt directories #
#####################
echo "... create directories"
mkdir -p /data/static
if [ -d /home/wger/static ] && [ ! -L /home/wger/static ]; then
    if [ -n "$(ls -A /home/wger/static 2> /dev/null)" ]; then
        cp -rnf /home/wger/static/* /data/static/
    fi
    rm -r /home/wger/static
fi
ln -sf /data/static /home/wger

mkdir -p /data/media
if [ -d /home/wger/media ] && [ ! -L /home/wger/media ]; then
    if [ -n "$(ls -A /home/wger/media 2> /dev/null)" ]; then
        cp -rnf /home/wger/media/* /data/media/
    fi
    rm -r /home/wger/media
fi
ln -sf /data/media /home/wger

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
