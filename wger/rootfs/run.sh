#!/bin/bashio

chmod +x /etc/cont-init.d/*
sed -i "s|/usr/bin/with-contenv|/usr/bin/env|g" /etc/cont-init.d/*
/./etc/cont-init.d/00-banner.sh

LOCATION=/data
mkdir -p "$LOCATION"
touch "$LOCATION"/database.sqlite || true
chown -R wger "$LOCATION" || true
chmod -R 777 "$LOCATION" || true
rm /home/wger/db/database.sqlite &>/dev/null || true
ln -s "$LOCATION"/database.sqlite /home/wger/db

python3 /home/wger/src/manage.py migrate || true

echo "Launch app"
su -l wger -s /bin/bash -c "exec /home/wger/entrypoint.sh"
