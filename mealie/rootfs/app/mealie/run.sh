#!/usr/bin/env bashio

##########
# BANNER #
##########

if bashio::supervisor.ping; then
    bashio::log.blue \
        '-----------------------------------------------------------'
    bashio::log.blue " Add-on: $(bashio::addon.name)"
    bashio::log.blue " $(bashio::addon.description)"
    bashio::log.blue \
        '-----------------------------------------------------------'

    bashio::log.blue " Add-on version: $(bashio::addon.version)"
    if bashio::var.true "$(bashio::addon.update_available)"; then
        bashio::log.magenta ' There is an update available for this add-on!'
        bashio::log.magenta \
            " Latest add-on version: $(bashio::addon.version_latest)"
        bashio::log.magenta ' Please consider upgrading as soon as possible.'
    else
        bashio::log.green ' You are running the latest version of this add-on.'
    fi

    bashio::log.blue " System: $(bashio::info.operating_system)" \
        " ($(bashio::info.arch) / $(bashio::info.machine))"
    bashio::log.blue " Home Assistant Core: $(bashio::info.homeassistant)"
    bashio::log.blue " Home Assistant Supervisor: $(bashio::info.supervisor)"

    bashio::log.blue \
        '-----------------------------------------------------------'
    bashio::log.blue \
        ' Please, share the above information when looking for help'
    bashio::log.blue \
        ' or support in, e.g., GitHub, forums or the Discord chat.'
    bashio::log.green \
        ' https://github.com/alexbelgium/hassio-addons'
    bashio::log.blue \
        '-----------------------------------------------------------'
fi


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
