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

##################
# Starting Redis #
##################
echo "Starting Redis..."
redis-server &
REDIS_PID=$!

##################
# Starting Celery #
##################
echo "Starting Celery..."
celery -A gramps_webapi.celery worker --loglevel=INFO --concurrency=2 &
CELERY_PID=$!

#################
# Staring nginx #
#################
echo "Starting nginx..."
exec nginx & bashio::log.info "Starting nginx"
NGINX_PID=$!

###############
# Starting App #
###############
echo "Starting Gramps Web App..."
/docker-entrypoint.sh gunicorn -w ${GUNICORN_NUM_WORKERS:-8} -b 0.0.0.0:5000 gramps_webapi.wsgi:app --timeout ${GUNICORN_TIMEOUT:-120} --limit-request-line 8190 &
APP_PID=$!

# Wait for all background processes
wait $REDIS_PID $CELERY_PID $APP_PID $NGINX_PID
