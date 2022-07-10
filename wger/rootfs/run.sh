#!/usr/bin/env bashio

chmod +x /etc/cont-init.d/*
sed -i "s|/usr/bin/with-contenv|/usr/bin/env|g" /etc/cont-init.d/*
/./etc/cont-init.d/00-banner.sh

LOCATION=/data
mkdir -p "$LOCATION"
chown -R wger "$LOCATION"
chmod -R 777 "$LOCATION"

echo "Launch app"
su -l wger -c "\
export WORKDIR="/home/wger/src" && \
cd /home/wger/src && \
echo "Defining database" && \
touch "$LOCATION"/database.sqlite && \
ln -s "$LOCATION"/database.sqlite /home/wger/db && \
echo "Updating database" && \
python3 /home/wger/src/manage.py migrate || true && \
echo "Starting app" && \
DOCKER_DIR=./extras/docker/development && \
if [ -f ~/.bashrc ]; then source ~/.bashrc; fi && \
export FROM_EMAIL='wger Workout Manager <wger@example.com>' && \
export DJANGO_DB_DATABASE=/data/database.sqlite && \
export DEBIAN_FRONTEND=noninteractive && \
LANG=en_US.UTF-8 && \
LANGUAGE=en_US:en && \
LC_ALL=en_US.UTF-8 && \
PYTHONDONTWRITEBYTECODE=1 && \
PYTHONUNBUFFERED=1 && \
PATH=/home/wger/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin && \
/bin/sh /home/wger/entrypoint.sh"
