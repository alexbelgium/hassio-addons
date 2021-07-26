#!/usr/bin/env bashio

set -e

# Get Reload Arg `run.sh reload` for dev server
ARG1=${1:-production}

# Get PUID/PGID
PUID=${PUID:-911}
PGID=${PGID:-911}

add_user() {
    groupmod -o -g "$PGID" abc
    usermod -o -u "$PUID" abc

    echo "
    User uid:    $(id -u abc)
    User gid:    $(id -g abc)
    "
    chown -R abc:abc /app
}

init() {
    # $MEALIE_HOME directory
    cd /app
    # Activate our virtual environment here
    . /opt/pysetup/.venv/bin/activate

    # Initialize Database Prerun
    poetry run python /app/mealie/db/init_db.py
    poetry run python /app/mealie/services/image/minify.py
}

# Migrations
# TODO
    # Migrations
    # Set Port from ENV Variable

if [ "$ARG1" == "reload" ]; then
    echo "Hot Reload!"

    init

    # Start API
    python /app/mealie/app.py
else
    echo "Production"

    add_user
    init

    # Web Server
    caddy start --config /app/Caddyfile

    # Start API
    gunicorn mealie.app:app -b 0.0.0.0:9000 -k uvicorn.workers.UvicornWorker -c /app/gunicorn_conf.py --p reload \
    & bashio::log.info "App started" 

#########
# NGINX #
#########

declare port
declare certfile
declare ingress_interface
declare ingress_port
declare keyfile

port=$(bashio::addon.port 80)
ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)
sed -i "s/%%port%%/${ingress_port}/g" /etc/nginx/servers/ingress.conf
sed -i "s/%%interface%%/${ingress_interface}/g" /etc/nginx/servers/ingress.conf
mkdir -p /var/log/nginx && touch /var/log/nginx/error.log

bashio::log.info "Nginx started for Ingress" 
exec nginx

fi 
