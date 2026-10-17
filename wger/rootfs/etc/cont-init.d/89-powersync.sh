#!/usr/bin/env bashio
# shellcheck shell=bash
#
# PowerSync — offline sync for the official wger mobile app (issue #2950).
#
# Opt-in and off by default. With POWERSYNC_ENABLED unset this script only clears a
# route a previous enabled run may have left behind, and then exits: the served nginx
# configuration and the running processes are exactly what they were without it.
#
# Runs at 89 so the nginx snippet is in place before 90-run.sh starts nginx, and so
# generated JWT keys land in /.env before 90-run.sh folds that file into /data/env.sh.

set -u

POWERSYNC_DIR=/opt/powersync
NGINX_PS_DIR=/etc/nginx/ps
JWT_DIR=/data/powersync
JWT_FILE="$JWT_DIR/jwt.env"
ENV_FILE=/.env

# A fresh install runs bootstrap, collectstatic, migrations and the exercise sync
# before gunicorn answers, which upstream and the add-on README both put in the
# tens of minutes. The barrier has to outlast that, not a typical restart.
DJANGO_WAIT_SECONDS=1800
DJANGO_WAIT_LOG_EVERY=60

# ha_entrypoint.sh's own service supervisor is unreachable here: it only runs when
# ha_entrypoint.sh is PID 1, and in this add-on it is a child of the upstream
# entrypoint — which is why 90-run.sh starts nginx with a bare "nginx &" too. So the
# restart policy is open-coded, and it retries indefinitely with a capped backoff
# rather than giving up: the Postgres this depends on is a separate add-on, and an
# update or restart of it takes it away for longer than a handful of quick retries.
# That matches the "restart: unless-stopped" upstream gives the PowerSync container.
RESTART_DELAY_MIN=5
RESTART_DELAY_MAX=60

# The Supervisor destroys and recreates the container on every add-on start, so this
# file is normally absent already. An out-of-band restart (docker restart, Portainer)
# does reuse the writable layer, and then a route left over from a previous run would
# point /ps/ at a service this run is not going to start.
rm -f "$NGINX_PS_DIR/location.conf"

enabled="${POWERSYNC_ENABLED:-false}"
if [ "${enabled,,}" != "true" ]; then
    exit 0
fi

bashio::log.info "PowerSync is enabled"

#########################
# Refuse bad prerequisites
#########################

# A cont-init script that exits nonzero is only logged by ha_entrypoint.sh, which
# then carries on, so there is nothing to be gained by failing hard here: say exactly
# what is missing, leave /ps/ unrouted, and let wger itself start normally.
refuse() {
    bashio::log.error "PowerSync not started: $1"
    bashio::log.error "See the PowerSync section of the add-on documentation."
    exit 0
}

case "${PS_DATABASE_URI:-}" in
    postgres://* | postgresql://*) ;;
    "") refuse "PS_DATABASE_URI is not set. PowerSync replicates from PostgreSQL only; wger must be pointed at a Postgres database with this variable." ;;
    *) refuse "PS_DATABASE_URI is not a PostgreSQL URI (${PS_DATABASE_URI%%:*}:...). PowerSync cannot replicate from anything else, SQLite included." ;;
esac

case "${PS_STORAGE_PG_URI:-}" in
    postgres://* | postgresql://*) ;;
    "") refuse "PS_STORAGE_PG_URI is not set. PowerSync keeps its sync buckets in a dedicated role inside the same Postgres database; set it to postgres://powersync_storage:<password>@<host>:<port>/<database>." ;;
    *) refuse "PS_STORAGE_PG_URI is not a PostgreSQL URI." ;;
esac

# wger builds the endpoint the app connects to as "<SITE_URL>/ps/", so only the scheme
# and a non-empty host are checked here, plus the shipped default, which no phone can
# reach. A trailing slash is tolerated.
site_url="${SITE_URL:-}"
site_url="${site_url%/}"

case "$site_url" in
    "") refuse "SITE_URL is not set. The app is handed <SITE_URL>/ps/ as the sync endpoint, so it has to be the URL your phone reaches wger on." ;;
    http://localhost | http://localhost:* | https://localhost | https://localhost:*)
        refuse "SITE_URL is still the default ${SITE_URL}, which no phone can reach. Set it to the URL you open wger on." ;;
    http:// | https://) refuse "SITE_URL has no host: ${SITE_URL}" ;;
    http://*/* | https://*/*) refuse "SITE_URL must not contain a path: ${SITE_URL}" ;;
    http://* | https://*) ;;
    *) refuse "SITE_URL must be an absolute http:// or https:// URL, got ${SITE_URL}" ;;
esac

#########################
# Django management helper
#########################

# The image's own ENV already carries PYTHONPATH and DJANGO_SETTINGS_MODULE, and
# cont-init runs under "sudo -E", so -E is all that is needed to hand them on.
django_manage() {
    (cd /home/wger/src && sudo -u wger -E python3 manage.py "$@")
}

#########################
# JWT keypair
#########################

# The same RS256 pair signs the app's tokens and the PowerSync token, and PowerSync
# fetches the public half back from Django over PS_JWKS_URL. Rotating it logs every
# app session out, so a pair is generated exactly once and then reused.
public_key="${JWT_PUBLIC_KEY:-}"
private_key="${JWT_PRIVATE_KEY:-}"
use_persisted_keys=false

# Both halves present, one line each. Checked on the way out of generation and again
# on reuse, since the file is at a path a user can reach and edit.
jwt_file_is_complete() {
    [ -f "$1" ] \
        && [ "$(grep -c '^JWT_PUBLIC_KEY=.' "$1")" -eq 1 ] \
        && [ "$(grep -c '^JWT_PRIVATE_KEY=.' "$1")" -eq 1 ]
}

if [ -n "$public_key" ] && [ -n "$private_key" ]; then
    bashio::log.info "Using the JWT keypair from the add-on configuration"
elif [ -n "$public_key" ] || [ -n "$private_key" ]; then
    refuse "only one half of the JWT keypair is configured. Set both JWT_PUBLIC_KEY and JWT_PRIVATE_KEY, or neither to have a pair generated."
elif [ -f "$JWT_FILE" ]; then
    jwt_file_is_complete "$JWT_FILE" \
        || refuse "$JWT_FILE does not hold one JWT_PUBLIC_KEY and one JWT_PRIVATE_KEY line. Delete it to have a fresh pair generated, which logs every app session out."
    bashio::log.info "Reusing the JWT keypair generated on a previous start"
    use_persisted_keys=true
else
    bashio::log.info "Generating a JWT keypair for PowerSync (kept at $JWT_FILE)"
    mkdir -p "$JWT_DIR"
    chmod 0700 "$JWT_DIR"

    jwt_tmp="$JWT_FILE.tmp"
    rm -f "$jwt_tmp"
    if ! django_manage generate-jwt-keys \
        | grep -E '^JWT_(PUBLIC|PRIVATE)_KEY=.+' > "$jwt_tmp"; then
        rm -f "$jwt_tmp"
        refuse "could not generate a JWT keypair (manage.py generate-jwt-keys failed)."
    fi
    if ! jwt_file_is_complete "$jwt_tmp"; then
        rm -f "$jwt_tmp"
        refuse "generate-jwt-keys did not return exactly one public and one private key."
    fi
    chmod 0600 "$jwt_tmp"
    # Rename last, so an interrupted start never leaves half a keypair behind.
    mv "$jwt_tmp" "$JWT_FILE"
    use_persisted_keys=true
fi

# Only when the persisted pair is the one in use. A configured pair is already in the
# environment, and exporting the generated one on top of it would win: 90-run.sh keeps
# the last assignment it reads out of /.env.
if [ "$use_persisted_keys" = true ]; then
    # 90-run.sh reads /.env back and re-exports every KEY=VALUE line into
    # /data/env.sh, which the upstream entrypoint sources before Django starts.
    # The values are the URL-safe base64 that generate-jwt-keys prints, so they
    # contain nothing that needs escaping inside double quotes.
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        printf '%s="%s"\n' "${line%%=*}" "${line#*=}" >> "$ENV_FILE"
    done < "$JWT_FILE"
fi

#########################
# nginx route
#########################

# Included from inside the existing server block in servers/nginx.conf. Written only
# here, so with the feature off the glob matches nothing.
mkdir -p "$NGINX_PS_DIR"
cat > "$NGINX_PS_DIR/location.conf" << 'EOF'
# Generated by 89-powersync.sh. Mirrors wger-project/docker config/nginx.conf.
location /ps/ {
    proxy_pass http://127.0.0.1:8080/;

    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $forwarded_proto;

    # The diagnostics app and the Web SDK upgrade this connection.
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;

    # Sync streams are long-lived streaming POSTs: they must not be buffered or
    # cut off by a short timeout.
    proxy_buffering off;
    proxy_read_timeout 1d;
    proxy_send_timeout 1d;

    # nginx consumes the upstream's X-Accel-Buffering, so re-send it for whatever
    # proxy sits in front of the add-on.
    add_header X-Accel-Buffering no always;
}
EOF

#########################
# Start the service
#########################

start_powersync() {
    local waited=0 wal_level=""

    # PowerSync replicates through the "powersync" publication, which wger creates in
    # its own migration 0027. Migrations run in the upstream entrypoint just before
    # gunicorn, so a replying API is the signal that the publication exists.
    bashio::log.info "PowerSync: waiting for wger to finish starting up"
    until curl -fsS -o /dev/null "http://127.0.0.1:8000/api/v2/version/" 2> /dev/null; do
        if [ "$waited" -ge "$DJANGO_WAIT_SECONDS" ]; then
            bashio::log.error "PowerSync: wger did not answer within ${DJANGO_WAIT_SECONDS}s, giving up"
            return 1
        fi
        sleep 5
        waited=$((waited + 5))
        if [ $((waited % DJANGO_WAIT_LOG_EVERY)) -eq 0 ]; then
            bashio::log.info "PowerSync: still waiting for wger (${waited}s)"
        fi
    done

    # Postgres only writes the logical WAL that PowerSync reads when wal_level is
    # logical, and the default in both Postgres add-ons is replica. Without this the
    # feature looks enabled and silently never syncs.
    wal_errors="$(mktemp)"
    wal_level="$(django_manage shell -c \
        "from django.db import connection; c = connection.cursor(); c.execute('SHOW wal_level'); print(c.fetchone()[0])" \
        2> "$wal_errors" | tail -n 1)"
    if [ "$wal_level" != "logical" ]; then
        bashio::log.error "PowerSync: the database reports wal_level=${wal_level:-unknown}, logical replication needs 'logical'"
        bashio::log.error "PowerSync: add \"wal_level = logical\" to the Postgres add-on configuration and restart it"
        # Most often this is not the setting at all but a database that cannot be
        # reached, and then the reason is only in here.
        [ -s "$wal_errors" ] && bashio::log.error "PowerSync: $(tail -n 3 "$wal_errors")"
        rm -f "$wal_errors"
        return 1
    fi
    rm -f "$wal_errors"

    # Idempotent, and creates the storage role with exactly the credentials in
    # PS_STORAGE_PG_URI, so whatever the user put there is what gets created.
    bashio::log.info "PowerSync: preparing the sync bucket storage"
    if ! django_manage setup-powersync-storage; then
        bashio::log.error "PowerSync: setup-powersync-storage failed; the PS_DATABASE_URI role needs to be able to create a role and a schema"
        return 1
    fi

    bashio::log.info "PowerSync: starting the service on 127.0.0.1:${PS_PORT}"
    (
        cd "$POWERSYNC_DIR" || exit 1
        delay="$RESTART_DELAY_MIN"
        while true; do
            rc=0
            sudo -u wger -E "$POWERSYNC_DIR/bin/node" service/lib/entry.js start -r unified || rc=$?
            if [ "$rc" -eq 0 ]; then
                # Same rule ha_entrypoint.sh applies to its own services: a clean exit
                # is not a crash, and restarting one fights the add-on shutting down.
                bashio::log.info "PowerSync exited cleanly, not restarting"
                break
            fi
            bashio::log.warning "PowerSync exited (code ${rc}), restarting in ${delay}s"
            sleep "$delay"
            delay=$((delay * 2))
            [ "$delay" -gt "$RESTART_DELAY_MAX" ] && delay="$RESTART_DELAY_MAX"
        done
    )
}

start_powersync &

bashio::log.info "PowerSync will be available at ${site_url}/ps/ once wger has started"
