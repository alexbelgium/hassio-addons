#!/usr/bin/env bashio

chmod +x /etc/cont-init.d/*
sed -i "s|/usr/bin/with-contenv|/usr/bin/env|g" /etc/cont-init.d/*
/./etc/cont-init.d/00-banner.sh

LOCATION=/data
mkdir -p "$LOCATION"
echo "Defining database"
touch "$LOCATION"/database.sqlite
ln -s "$LOCATION"/database.sqlite /home/wger/db

echo "Updating database"
python3 manage.py migrate || true

echo "Defining permissions"
chown -R wger:wger "$LOCATION"
chown -R wger:wger "/home/wger"
chmod -R 777 "$LOCATION"

echo "Launch app"
su -l wger -c "/usr/bin/env bash /home/wger/entrypoint.sh"
