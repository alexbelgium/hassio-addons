#!/bin/bash

LOCATION=/data
python3 manage.py migrate || true
mkdir -p "$LOCATION"
touch "$LOCATION"/database.sqlite || true
chown -R wger "$LOCATION" || true
chmod -R 777 "$LOCATION" || true
rm /home/wger/db/database.sqlite &>/dev/null || true
ln -s "$LOCATION"/database.sqlite /home/wger/db

echo "Launch app"
su -H -u wger bash -c /./home/wger/entrypoint.sh
