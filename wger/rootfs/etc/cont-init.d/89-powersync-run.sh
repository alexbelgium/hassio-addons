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
#
# The "-run" in the name is load-bearing. Settings reach a cont-init script by being
# injected after its shebang, and the two mechanisms use different globs:
# 00-global_var.sh (add-on options and env_vars) injects into /etc/cont-init.d/*.sh,
# while 01-config_yaml.sh (the CONFIG_LOCATION file this add-on documents for extra
# variables) injects into /etc/cont-init.d/*run* . Matching both is what lets this
# script see the same settings 90-run.sh hands to Django.

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
DJANGO_WAIT_LOG_EVERY=300

# ha_entrypoint.sh's own service supervisor is unreachable here: it only runs when
# ha_entrypoint.sh is PID 1, and in this add-on it is a child of the upstream
# entrypoint — which is why 90-run.sh starts nginx with a bare "nginx &" too. So the
# restart policy is open-coded, and it retries indefinitely with a capped backoff
# rather than giving up: the Postgres this depends on is a separate add-on, and an
# update or restart of it takes it away for longer than a handful of quick retries.
# That matches the "restart: unless-stopped" upstream gives the PowerSync container.
RESTART_DELAY_MIN=5
RESTART_DELAY_MAX=60

# The one-off SQLite import runs here in cont-init, which is before the upstream
# entrypoint migrates and bootstraps, so waiting here is what stops that bootstrap from
# racing the import: cont-init is synchronous. The Postgres add-on starts before regular
# add-ons, so this is a margin rather than an expected wait.
POSTGRES_WAIT_SECONDS=300
IMPORT_DIR=/data/powersync/import
IMPORT_FAILED_MARKER=/data/powersync/import-failed

# The Supervisor destroys and recreates the container on every add-on start, so this
# file is normally absent already. An out-of-band restart (docker restart, Portainer)
# does reuse the writable layer, and then a route left over from a previous run would
# point /ps/ at a service this run is not going to start.
rm -f "$NGINX_PS_DIR/location.conf"

# Cleared here and written only when an import fails, so it can never outlive the boot
# that created it. The upstream entrypoint refuses to start wger while it exists; see
# the import function and the sed in the Dockerfile.
rm -f "$IMPORT_FAILED_MARKER"

enabled="${POWERSYNC_ENABLED:-false}"
if [ "${enabled,,}" != "true" ]; then
    exit 0
fi

bashio::log.info "PowerSync is enabled"

# From here on the marker is armed rather than written on failure. Anything that stops
# this script - a refused prerequisite, a failed import, an error nobody anticipated -
# then leaves it in place, and the patched upstream entrypoint refuses to start wger.
#
# That is the fail-safe direction. Letting the boot continue is what loses the data: the
# entrypoint would bootstrap the empty Postgres database into a new instance with its own
# admin user, and from then on this script would see a database holding users and skip
# the import for good. The rows would still be in the SQLite file, and the add-on would
# never offer to move them again.
#
# It is armed only when Django is actually about to use Postgres and there is something
# to move, so none of this applies to a database wger is not being pointed at. The two
# places that clear it are a completed import and a target that already holds data.
case "${PS_DATABASE_URI:-}" in
    postgres://* | postgresql://*)
        if [ -s "${DJANGO_DB_DATABASE:-/data/database.sqlite}" ]; then
            mkdir -p "$(dirname "$IMPORT_FAILED_MARKER")"
            touch "$IMPORT_FAILED_MARKER"
        fi
        ;;
esac

#########################
# Refuse bad prerequisites
#########################

# A cont-init script that exits nonzero is only logged by ha_entrypoint.sh, which then
# carries on, so there is nothing to be gained by failing hard here: say exactly what is
# missing, leave /ps/ unrouted, and let wger itself start normally.
#
# refuse() returns rather than exits, and the single caller below turns that into a
# top-level exit. ha_entrypoint.sh can run a cont-init script either way - it execs it,
# or with ha_entry_source=true it rewrites "exit N" to "return N || exit N" and sources
# it - and an exit inside a function would, in the second mode, return from the function
# only and let the rest of this script run on a configuration it had just rejected.
refuse() {
    bashio::log.error "PowerSync not started: $1"
    bashio::log.error "See the PowerSync section of the add-on documentation."
    return 1
}

#########################
# Helpers
#########################

# The image's own ENV already carries PYTHONPATH and DJANGO_SETTINGS_MODULE, and
# cont-init runs under "sudo -E", so -E is all that is needed to hand them on.
django_manage() {
    (cd /home/wger/src && sudo -u wger -E python3 manage.py "$@")
}

# The same, pointed at a SQLite file instead. PS_DATABASE_URI has to go: wger's
# settings/main.py checks it before the DJANGO_DB_* block, so it would win.
sqlite_manage() {
    local database="$1"
    shift
    (
        cd /home/wger/src && sudo -u wger -E env -u PS_DATABASE_URI \
            DJANGO_DB_ENGINE=django.db.backends.sqlite3 \
            DJANGO_DB_DATABASE="$database" \
            python3 manage.py "$@"
    )
}

# Both halves present, one line each. Checked on the way out of generation and again on
# reuse, since the file is at a path a user can reach and edit.
jwt_file_is_complete() {
    [ -f "$1" ] \
        && [ "$(grep -c '^JWT_PUBLIC_KEY=.' "$1")" -eq 1 ] \
        && [ "$(grep -c '^JWT_PRIVATE_KEY=.' "$1")" -eq 1 ]
}

# Everything that can reject the configuration lives here, so a rejection is a return
# and the single caller below turns it into one top-level exit.
prepare() {
    case "${PS_DATABASE_URI:-}" in
        postgres://* | postgresql://*) ;;
        "") refuse "PS_DATABASE_URI is not set. PowerSync replicates from PostgreSQL only; wger must be pointed at a Postgres database with this variable." || return 1 ;;
        *) refuse "PS_DATABASE_URI is not a PostgreSQL URI (${PS_DATABASE_URI%%:*}:...). PowerSync cannot replicate from anything else, SQLite included." || return 1 ;;
    esac

    case "${PS_STORAGE_PG_URI:-}" in
        postgres://* | postgresql://*) ;;
        "") refuse "PS_STORAGE_PG_URI is not set. PowerSync keeps its sync buckets in a dedicated role inside the same Postgres database; set it to postgres://powersync_storage:<password>@<host>:<port>/<database>." || return 1 ;;
        *) refuse "PS_STORAGE_PG_URI is not a PostgreSQL URI." || return 1 ;;
    esac

    # wger builds the endpoint the app connects to as "<SITE_URL>/ps/", so only the
    # scheme and a non-empty host are checked here, plus the shipped default, which no
    # phone can reach. A trailing slash is tolerated.
    site_url="${SITE_URL:-}"
    site_url="${site_url%/}"

    case "$site_url" in
        "") refuse "SITE_URL is not set. The app is handed <SITE_URL>/ps/ as the sync endpoint, so it has to be the URL your phone reaches wger on." || return 1 ;;
        http://localhost | http://localhost:* | https://localhost | https://localhost:*)
            refuse "SITE_URL is still the default ${SITE_URL}, which no phone can reach. Set it to the URL you open wger on." || return 1 ;;
        http:// | https:// | http://:* | https://:*) refuse "SITE_URL has no host: ${SITE_URL}" || return 1 ;;
        http://*/* | https://*/*) refuse "SITE_URL must not contain a path: ${SITE_URL}" || return 1 ;;
        # wger appends "/<path>/" to SITE_URL, so a query or fragment here would swallow
        # the /ps/ it is meant to produce.
        *\?* | *'#'*) refuse "SITE_URL must not contain a query or fragment: ${SITE_URL}" || return 1 ;;
        http://* | https://*) ;;
        *) refuse "SITE_URL must be an absolute http:// or https:// URL, got ${SITE_URL}" || return 1 ;;
    esac

    # The same RS256 pair signs the app's tokens and the PowerSync token, and PowerSync
    # fetches the public half back from Django over PS_JWKS_URL. Rotating it logs every
    # app session out, so a pair is generated exactly once and then reused.
    local public_key="${JWT_PUBLIC_KEY:-}"
    local private_key="${JWT_PRIVATE_KEY:-}"
    local jwt_tmp line
    use_persisted_keys=false

    if [ -n "$public_key" ] && [ -n "$private_key" ]; then
        bashio::log.info "Using the JWT keypair from the add-on configuration"
    elif [ -n "$public_key" ] || [ -n "$private_key" ]; then
        refuse "only one half of the JWT keypair is configured. Set both JWT_PUBLIC_KEY and JWT_PRIVATE_KEY, or neither to have a pair generated." || return 1
    elif [ -f "$JWT_FILE" ]; then
        jwt_file_is_complete "$JWT_FILE" \
            || { refuse "$JWT_FILE does not hold one JWT_PUBLIC_KEY and one JWT_PRIVATE_KEY line. Delete it to have a fresh pair generated, which logs every app session out."; return 1; }
        bashio::log.info "Reusing the JWT keypair generated on a previous start"
        use_persisted_keys=true
    else
        bashio::log.info "Generating a JWT keypair for PowerSync (kept at $JWT_FILE)"
        mkdir -p "$JWT_DIR"
        # 0755, not 0700: the import directory lives under this one and is read by the
        # wger user, which needs search permission on every component of the path. The
        # key file itself is what is protected, by its own 0600 below. The chmod is
        # explicit so that a 0700 left here by an earlier version of the add-on - /data
        # survives upgrades - is repaired rather than inherited.
        chmod 0755 "$JWT_DIR"

        jwt_tmp="$JWT_FILE.tmp"
        rm -f "$jwt_tmp"
        if ! django_manage generate-jwt-keys \
            | grep -E '^JWT_(PUBLIC|PRIVATE)_KEY=.+' > "$jwt_tmp"; then
            rm -f "$jwt_tmp"
            refuse "could not generate a JWT keypair (manage.py generate-jwt-keys failed)." || return 1
        fi
        if ! jwt_file_is_complete "$jwt_tmp"; then
            rm -f "$jwt_tmp"
            refuse "generate-jwt-keys did not return exactly one public and one private key." || return 1
        fi
        chmod 0600 "$jwt_tmp"
        # Rename last, so an interrupted start never leaves half a keypair behind.
        mv "$jwt_tmp" "$JWT_FILE"
        use_persisted_keys=true
    fi

    # Only when the persisted pair is the one in use. A configured pair is already in
    # the environment, and exporting the generated one on top of it would win:
    # 90-run.sh keeps the last assignment it reads out of /.env.
    if [ "$use_persisted_keys" = true ]; then
        # 90-run.sh reads /.env back and re-exports every KEY=VALUE line into
        # /data/env.sh, which the upstream entrypoint sources before Django starts, so
        # only the two lines this script put there may travel: anything else in an
        # edited key file would become an assignment the entrypoint evaluates.
        # The values are the URL-safe base64 that generate-jwt-keys prints, so they
        # contain nothing that needs escaping inside double quotes.
        while IFS= read -r line; do
            case "$line" in
                JWT_PUBLIC_KEY=* | JWT_PRIVATE_KEY=*) ;;
                *) continue ;;
            esac
            printf '%s="%s"\n' "${line%%=*}" "${line#*=}" >> "$ENV_FILE"
        done < "$JWT_FILE"
    fi
}

#########################
# One-off SQLite import
#########################

# Mirrors wger's own database_initialised() in wger/tasks.py: a database that cannot be
# reached is an error rather than an empty database, and "no users at all" is upstream's
# definition of a database that was never set up, because the admin user is created as
# the last step of its bootstrap. Only connection failures that waiting cannot fix are
# fatal; every other OperationalError is retried. Prints a state, a tab and a one-line
# detail.
target_database_state() {
    django_manage shell 2> /dev/null << 'PROBE' | tail -n 1
from django.db import DatabaseError, OperationalError, connection

try:
    connection.ensure_connection()
except Exception as error:
    # psycopg can spread one failure over several lines, one per address tried.
    message = ' '.join(str(error).split()) or type(error).__name__
    fatal_messages = (
        'password authentication failed',
        'no password supplied',
        'does not exist',
        'no pg_hba.conf entry',
    )
    fatal = not isinstance(error, OperationalError) or any(
        text in message.lower() for text in fatal_messages
    )
    print(f"{'fatal' if fatal else 'retryable'}\t{message}")
else:
    from django.contrib.auth.models import User

    try:
        print('populated' if User.objects.exists() else 'empty')
    except DatabaseError:
        print('fresh')
PROBE
}

# Copy the contents of the add-on's SQLite database into the configured Postgres one,
# once, the first time PowerSync is enabled.
#
# The SQLite file is never opened by this: it is copied first and every read happens
# against the copy, so disabling PowerSync again (by removing PS_DATABASE_URI) returns
# to the original database exactly as it was.
#
# It also never overwrites: an import happens only into a Postgres database that holds
# no users, so re-enabling the feature later leaves whatever is already in Postgres
# alone. The two databases do not stay in sync afterwards - whichever one wger is
# pointed at is the live one.
import_sqlite_data() {
    local sqlite_db="${DJANGO_DB_DATABASE:-/data/database.sqlite}"
    local waited=0 probe state detail
    local dump="$IMPORT_DIR/dump.json" copy="$IMPORT_DIR/database.sqlite"

    if [ ! -s "$sqlite_db" ]; then
        bashio::log.info "No SQLite database at $sqlite_db, nothing to import"
        rm -f "$IMPORT_FAILED_MARKER"
        return 0
    fi

    bashio::log.info "Checking whether the Postgres database already holds wger data"
    while true; do
        probe="$(target_database_state)"
        IFS=$'\t' read -r state detail <<< "$probe"
        case "$state" in
        fresh | empty | populated)
            break
            ;;
        retryable)
            if [ "$waited" -ge "$POSTGRES_WAIT_SECONDS" ]; then
                bashio::log.error "PowerSync: the Postgres database is still unreachable after ${POSTGRES_WAIT_SECONDS}s: $detail"
                bashio::log.error "PowerSync: the SQLite database itself is untouched at $sqlite_db"
                return 1
            fi
            [ "$waited" -eq 0 ] && bashio::log.info "PowerSync: waiting for the Postgres database: $detail"
            sleep 5
            waited=$((waited + 5))
            ;;
        fatal)
            bashio::log.error "PowerSync: the Postgres connection error cannot be fixed by waiting: $detail"
            bashio::log.error "PowerSync: the SQLite database itself is untouched at $sqlite_db"
            return 1
            ;;
        *)
            bashio::log.error "PowerSync: the Postgres probe returned an unexpected result: ${probe:-no output}"
            bashio::log.error "PowerSync: the SQLite database itself is untouched at $sqlite_db"
            return 1
            ;;
        esac
    done

    if [ "$state" = "populated" ]; then
        bashio::log.info "The Postgres database already holds wger data; leaving it as it is and importing nothing"
        rm -f "$IMPORT_FAILED_MARKER"
        return 0
    fi

    bashio::log.info "Importing the SQLite database into Postgres (one-off, $sqlite_db is only read)"
    # The dump holds every row of the database, password hashes included, and the copy
    # is a second copy of the same file. Both are removed again below.
    rm -rf "$IMPORT_DIR"
    mkdir -p "$IMPORT_DIR"
    # dumpdata and loaddata run as the wger user, which needs search permission on
    # every component down to the files below, so the parent cannot stay root-only.
    chmod 0755 "$(dirname "$IMPORT_DIR")"
    chmod 0700 "$IMPORT_DIR"
    if ! chown wger "$IMPORT_DIR"; then
        bashio::log.error "PowerSync: could not give $IMPORT_DIR to the wger user, which is what reads the database"
        rm -rf "$IMPORT_DIR"
        return 1
    fi

    if ! cp -p "$sqlite_db" "$copy"; then
        bashio::log.error "PowerSync: could not copy the SQLite database, skipping the import"
        rm -rf "$IMPORT_DIR"
        return 1
    fi
    if ! chown wger "$copy"; then
        bashio::log.error "PowerSync: could not give the database copy to the wger user"
        rm -rf "$IMPORT_DIR"
        return 1
    fi

    # Upstream-deleted models leave content types whose permissions groups still hold,
    # and loaddata cannot resolve those in a freshly migrated Postgres.
    if ! sqlite_manage "$copy" remove_stale_contenttypes --no-input; then
        bashio::log.error "PowerSync: removing stale content types from the database copy failed, nothing was written to Postgres"
        bashio::log.error "PowerSync: the SQLite database itself is untouched at $sqlite_db"
        rm -rf "$IMPORT_DIR"
        return 1
    fi

    # Dumped from the copy, with the tables Django rebuilds for itself left out: content
    # types and permissions are recreated by migrate, and sessions point at them. wger
    # does not install django.contrib.admin, so there is no admin.logentry to exclude:
    # naming it makes dumpdata fail with "Unknown model" (#3134). --natural-foreign keeps
    # those references resolvable; primary keys are deliberately kept as they are so the
    # rows land unchanged.
    if ! sqlite_manage "$copy" dumpdata \
        --natural-foreign \
        --exclude contenttypes \
        --exclude auth.Permission \
        --exclude sessions.session \
        --output "$dump"; then
        bashio::log.error "PowerSync: reading the SQLite database failed, nothing was written to Postgres"
        bashio::log.error "PowerSync: the SQLite database itself is untouched at $sqlite_db"
        rm -rf "$IMPORT_DIR"
        return 1
    fi

    if ! django_manage migrate --no-input; then
        bashio::log.error "PowerSync: creating the schema in Postgres failed, the import is incomplete"
        rm -rf "$IMPORT_DIR"
        return 1
    fi

    # loaddata resets the Postgres sequences for every model it loaded, so the next
    # insert does not collide with an imported primary key. It runs in one transaction,
    # so a failure leaves the schema without rows and the next start imports again.
    if ! django_manage loaddata "$dump"; then
        bashio::log.error "PowerSync: writing the data into Postgres failed and was rolled back; the import is retried on the next start"
        bashio::log.error "PowerSync: the SQLite database itself is untouched at $sqlite_db"
        rm -rf "$IMPORT_DIR"
        return 1
    fi

    rm -rf "$IMPORT_DIR"
    rm -f "$IMPORT_FAILED_MARKER"
    bashio::log.info "Import finished. wger is now running on Postgres; $sqlite_db is left behind unchanged in case you want to go back"
    return 0
}

# 90-run.sh generates SECRET_KEY but runs after this script, so the manage.py calls here
# read it themselves; env_vars keep precedence. The first boot of a new install still
# gets upstream's missing-key warning once.
if [ -z "${SECRET_KEY:-}" ] && [ -f /data/secrets.env ]; then
    secret_key="$(sed -n '/^SECRET_KEY=/{s///p;q}' /data/secrets.env)"
    [ -n "$secret_key" ] && export SECRET_KEY="$secret_key"
fi

if ! prepare; then
    # The marker armed above is deliberately left in place; see the comment there.
    exit 0
fi

if ! import_sqlite_data; then
    bashio::log.error "PowerSync not started: the SQLite import did not complete, see above."
    bashio::log.error "wger will not be started, so that the empty Postgres database is not set up as a new instance and your SQLite data stays importable. Fix the cause, or remove PS_DATABASE_URI to go back to SQLite."
    exit 0
fi

#########################
# nginx route
#########################

# Included from inside the existing server block in servers/nginx.conf. Written only
# here, so with the feature off the glob matches nothing.
mkdir -p "$NGINX_PS_DIR"
cat > "$NGINX_PS_DIR/location.conf" << 'EOF'
# Generated by 89-powersync-run.sh. Mirrors wger-project/docker config/nginx.conf.
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
    # stderr is left alone on purpose: when this fails it is usually a database that
    # cannot be reached rather than the setting, and the reason belongs in the log.
    wal_level="$(django_manage shell -c \
        "from django.db import connection; c = connection.cursor(); c.execute('SHOW wal_level'); print(c.fetchone()[0])" \
        | tail -n 1)"
    if [ "$wal_level" != "logical" ]; then
        bashio::log.error "PowerSync: the database reports wal_level=${wal_level:-unknown}, logical replication needs 'logical'"
        bashio::log.error "PowerSync: add \"wal_level = logical\" to the Postgres add-on configuration and restart it"
        return 1
    fi

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
                # is not a crash. Nothing signals this process at shutdown - it is
                # orphaned when cont-init returns, exactly like the nginx 90-run.sh
                # starts - so the container runtime is what finally stops it.
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
