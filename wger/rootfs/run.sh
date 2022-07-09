#!/bin/bashio

LOCATION=/data
python3 manage.py migrate || true
mkdir -p "$LOCATION"
touch "$LOCATION"/database.sqlite || true
chown -R wger "$LOCATION" || true
chmod -R 777 "$LOCATION" || true
rm /home/wger/db/database.sqlite &>/dev/null || true
ln -s "$LOCATION"/database.sqlite /home/wger/db

chmod +x /etc/cont-init.d/*
/./etc/cont-init.d/*

echo "Launch app"
su -u wger bash -c /./home/wger/entrypoint.sh
