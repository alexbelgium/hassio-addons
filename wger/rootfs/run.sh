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
pip install -e .
exec /home/wger/entrypoint.sh
#cd /home/wger/src || true
#sed -i "s|manage.py|/home/wger/src/manage.py|g" /home/wger/entrypoint.sh
#sed -i "s|wger bootstrap|/home/wger/src/wger bootstrap|g" /home/wger/entrypoint.sh
#su wger -c "/usr/bin/env bash /home/wger/entrypoint.sh"
