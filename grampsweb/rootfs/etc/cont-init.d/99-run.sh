#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# Set structure #
#################
cp -rf /app /config
rm -r /app
ln -s /config /app

#####################
# Create secret key #
#####################
# Check if the secret key is defined in addon options
if bashio::config.has_value "GRAMPSWEB_SECRET_KEY"; then
    bashio::log.warning "Using the secret key defined in the addon options."
    export SECRET_KEY="$(bashio::config "GRAMPSWEB_SECRET_KEY")"
    export GRAMPSWEB_SECRET_KEY="$SECRET_KEY"
else
    # Check if the secret file exists; if not, create a new one
    if [ ! -s /config/secret/secret ]; then
        bashio::log.warning "No secret key found in /config/secret/secret, generating a new one."
        mkdir -p /config/secret
        python3 -c "import secrets; print(secrets.token_urlsafe(32))" | tr -d "\n" > /config/secret/secret
        bashio::log.warning "New secret key generated and stored in /config/secret/secret"
    fi
    bashio::log.warning "Using existing secret key from /config/secret/secret."
    bashio::log.warning "Secret key saved to addon options."
    export SECRET_KEY="$(cat /config/secret/secret)"
    bashio::addon.option "GRAMPSWEB_SECRET_KEY" "$SECRET_KEY"
    export GRAMPSWEB_SECRET_KEY="$SECRET_KEY"
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
