#!/usr/bin/env bashio

chmod +x /etc/cont-init.d/*
sed -i "s|/usr/bin/with-contenv|/usr/bin/env|g" /etc/cont-init.d/*
/./etc/cont-init.d/00-banner.sh

LOCATION=/data
mkdir -p "$LOCATION"

if [ ! -f "$LOCATION"/database.sqlite ]; then
  if [ -f "/home/wger/db/database.sqlite" ]; then
    cp /home/wger/db/database.sqlite "$LOCATION"/database.sqlite
  else
    touch "$LOCATION"/database.sqlite
  fi
fi

chown -R wger "$LOCATION"
chmod -R 777 "$LOCATION"
rm /home/wger/db/database.sqlite || true
ln -s "$LOCATION"/database.sqlite /home/wger/db

python3 manage.py migrate || true

echo "Launch app"
su -m wger -c "\
DOCKER_DIR=./extras/docker/development && \
/bin/sh -c mkdir ~/media     && \
pip3 install -e .     && \
mkdir ~/static     && \
mkdir ~/db/ && \
if [ -f .env ]; then export $(echo $(cat .env | sed 's/#.*//g'| xargs) | envsubst); fi && \
if [ -f ~/.bashrc ]; then source ~/.bashrc; fi && \
cd /home/wger/src && \
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
