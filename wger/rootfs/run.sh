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
su -l wger -c "\
export S6_CMD_WAIT_FOR_SERVICES=1 \
S6_CMD_WAIT_FOR_SERVICES_MAXTIME=300000 \
S6_SERVICES_GRACETIME=300000 \
PATH=/home/wger/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
FROM_EMAIL='wger Workout Manager <wger@example.com>' \
DJANGO_DB_DATABASE=/data/database.sqlite \
DEBIAN_FRONTEND=noninteractive \
LANG=en_US.UTF-8 \
LANGUAGE=en_US:en \
LC_ALL=en_US.UTF-8 \
PYTHONDONTWRITEBYTECODE=1 \
PYTHONUNBUFFERED=1 \
WORKDIR="/home/wger/src" && \
cd /home/wger/src && \
DOCKER_DIR=./extras/docker/development && \
if [ -f ~/.bashrc ]; then source ~/.bashrc; fi && \
/bin/sh /home/wger/entrypoint.sh"
