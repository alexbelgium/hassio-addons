#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# Set structure #
#################


for folders in users indexdir database secret media cache thumbnail_cache grampsdb; do
    mkdir -p /config/"$folders"
    if [ -d /app/"$folders" ] && [ "$(ls -A /app/"$folders")" ]; then
        cp -rf /app/"$folders"/* /config/"$folders"
    fi
    rm -rf /app/"$folders"
    ln -sf /config/"$folders" /app/"$folders"
done

if [ -d /root/.gramps/grampsdb ] && [ "$(ls -A /root/.gramps/grampsdb)" ]; then
    cp -rf /root/.gramps/grampsdb/* /config/grampsdb
    rm -rf /root/.gramps/grampsdb
    ln -sf /config/grampsdb /root/.gramps/grampsdb
fi

#####################
# Create secret key #
#####################
if [ ! -s /config/secret/secret ]
then
    mkdir -p /config/secret
    python3 -c "import secrets;print(secrets.token_urlsafe(32))"  | tr -d "\n" > /config/secret/secret
fi
# use the secret key if none is set (will be overridden by config file if present)
if [ -z "$SECRET_KEY" ]
then
    export SECRET_KEY=$(cat /config/secret/secret)
fi

##################
# Starting Redis #
##################
echo "Starting Redis..."
redis-server &
REDIS_PID=$!

###############
# Starting App #
###############
echo "Starting Gramps Web App..."
/docker-entrypoint.sh gunicorn -w ${GUNICORN_NUM_WORKERS:-8} -b 0.0.0.0:5000 gramps_webapi.wsgi:app --timeout ${GUNICORN_TIMEOUT:-120} --limit-request-line 8190 &
APP_PID=$!

##################
# Starting Celery #
##################
bashio::net.wait_for 5000 localhost 900
echo "Starting Celery..."
celery -A gramps_webapi worker --loglevel=INFO --concurrency=2 &
CELERY_PID=$!

#################
# Staring nginx #
#################
echo "Starting nginx..."
exec nginx & bashio::log.info "Starting nginx"
NGINX_PID=$!

# Wait for all background processes
wait $REDIS_PID $CELERY_PID $APP_PID $NGINX_PID
