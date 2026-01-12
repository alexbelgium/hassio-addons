#!/command/with-contenv bashio
# shellcheck shell=bash

set -e

# Check for required arguments
if [ $# -ne 3 ]; then
    bashio::log.error "[ssl-check-generate.sh] missing: <certfile> <keyfile> <selfsigned>"
    exit 1
fi

bashio::log.debug "SSL Certificate check"

renew_days=90

certfile="$1"
keyfile="$2"
selfsigned=${3:-true}

if [ ! -f "$certfile" ] || [ ! -f "$keyfile" ]; then
    if [ "$selfsigned" = "true" ]; then
        /usr/local/bin/ssl-keygen.sh "$certfile" "$keyfile"
        exit 0
    else
        bashio::log.error "[ssl-check-generate.sh] either certfile, keyfile, or both are missing"
        exit 1
    fi
fi

enddate=$(openssl x509 -enddate -noout -in "$certfile" 2>/dev/null || true)
if [ -n "$enddate" ]; then
    expiry_date=$(echo "$enddate" | cut -d= -f2 | sed 's/ GMT$//')
    expiry_ts=$(date -d "$expiry_date" +%s)
    now_ts=$(date +%s)
    days_left=$(( (expiry_ts - now_ts) / 86400 ))

    if [ "$days_left" -le "$renew_days" ]; then
        bashio::log.info "Self-signed cert expiring in $days_left days, regenerating..."
        /usr/local/bin/ssl-keygen.sh "$certfile" "$keyfile"
    fi
else
    bashio::log.error "Unable to determine ssl certificate expiry date"
fi

if pgrep -x nginx >/dev/null 2>&1; then
    nginx -s reload
fi