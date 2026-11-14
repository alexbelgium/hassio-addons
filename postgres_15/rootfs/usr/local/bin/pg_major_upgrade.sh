#!/usr/bin/env bash
# shellcheck shell=bash
#
# Prepare the cluster in $PGDATA for this image, before the server is opened to applications:
# bring its extensions to the versions the image ships, then upgrade it to the image's
# PostgreSQL major when it is from an older one.
#
#   exit 0   nothing had to change (or a fresh install)
#   exit 10  extensions updated and/or cluster upgraded: $PGDATA is ready for this image
#   exit 11  same major, but the extensions of a database could not be updated
#   exit 1   the upgrade failed or was skipped: run the server of the major $PGDATA is from
#   exit 2   this image cannot run the cluster at all (newer than the image, or no binaries)
#
# The upgrade works on a copy under $PGDATA.upgrade. The cluster in $PGDATA is replaced by a
# rename once the upgraded copy has been started and checked, so every failure before that
# leaves it as it was. Plain bash, no bashio: the image build runs this as a self-test.
set -uo pipefail

PGDATA="${PGDATA:?PGDATA is not set}"
NEW="${PG_MAJOR:?PG_MAJOR is not set}"
BIN="${PG_BINARIES_DIR:-/usr/lib/postgresql}"
WORK="$PGDATA.upgrade"
FAILED="$PGDATA.upgrade_failed"
LOGS="$PGDATA.upgrade_logs"
# Add-on version whose extensions the cluster was last brought to. Inside the cluster, so that
# it is restored, copied and replaced together with it
STAMP="$PGDATA/addon_extensions_version"
KEEP_DAYS=7
PORT=50432
CHANGED=false
# Empty in the test harness, where there is no root to drop from
read -r -a AS_PG <<< "${PG_UPGRADE_RUNAS-gosu postgres}"
# Only what goes wrong is worth showing from the private servers
export PGOPTIONS="-c client_min_messages=warning"

log() { echo "[pg_upgrade] $*"; }

# psql against the private server: q <bindir> <database> [psql args]
q() {
    local bindir="$1" db="$2"
    shift 2
    # Through the environment: -d would read a name such as "a=b" as a connection string
    PGDATABASE="$db" "${AS_PG[@]}" "$bindir/psql" -h "$SOCK" -p "$PORT" -U "$SUPERUSER" -v ON_ERROR_STOP=1 -AtqX "$@"
}

databases() {
    q "$1" template1 -c "SELECT datname FROM pg_database WHERE datallowconn AND datname <> 'template0' ORDER BY 1"
}

# Private server, reachable through a unix socket only: server <bindir> <datadir> start|stop
server() {
    if [ "$3" = start ]; then
        "${AS_PG[@]}" "$1/pg_ctl" -w -t 3600 -D "$2" -l "$SOCK/server.log" -o "$SERVER_OPTS" start > /dev/null
    else
        "${AS_PG[@]}" "$1/pg_ctl" -w -t 3600 -D "$2" -m fast stop > /dev/null
    fi
}

# Bring the extensions of every database to the version this image ships, with the server of
# the cluster's own major: update_extensions <major>
update_extensions() {
    local bindir="$BIN/$1/bin" db rc=0

    chmod 700 "$PGDATA"
    # Bootstrap superuser, which is not necessarily the POSTGRES_USER option of today
    SUPERUSER="$("${AS_PG[@]}" "$bindir/postgres" --single -D "$PGDATA" template1 <<< "SELECT rolname FROM pg_authid WHERE oid = 10" 2> /dev/null \
        | sed -n 's/.*rolname = "\(.*\)".*/\1/p')"
    [ -n "$SUPERUSER" ] || { log "Could not read the superuser of the cluster"; return 1; }

    server "$bindir" "$PGDATA" start || return 1
    databases "$bindir" > "$SOCK/databases" || rc=1
    while IFS= read -r db; do
        # pgvecto.rs is gone from the image; where nothing depends on it, it can simply go
        [ -f "$BIN/$1/lib/vectors.so" ] || q "$bindir" "$db" -c "DROP EXTENSION IF EXISTS vectors" || rc=1
        q "$bindir" "$db" -c "SELECT format('ALTER EXTENSION %I UPDATE;', e.extname) FROM pg_extension e
            JOIN pg_available_extensions a ON a.name = e.extname
            WHERE EXISTS (SELECT FROM pg_extension_update_paths(e.extname) p
                WHERE p.source = e.extversion AND p.target = a.default_version AND p.path IS NOT NULL)" > "$SOCK/extensions.sql" || { rc=1; continue; }
        # A VectorChord index cannot be read by a library of another version until it is rebuilt
        if grep -qx 'ALTER EXTENSION vchord UPDATE;' "$SOCK/extensions.sql"; then
            q "$bindir" "$db" -c "SELECT format('REINDEX INDEX %I.%I;', n.nspname, c.relname) FROM pg_class c
                JOIN pg_am a ON a.oid = c.relam JOIN pg_namespace n ON n.oid = c.relnamespace
                WHERE c.relkind = 'i' AND a.amname LIKE 'vchord%'" >> "$SOCK/extensions.sql" || { rc=1; continue; }
        fi
        if [ -s "$SOCK/extensions.sql" ]; then
            log "Database $db: $(tr '\n' ' ' < "$SOCK/extensions.sql")"
            # One transaction: the extension and its indexes never get out of step, whatever
            # interrupts this
            if q "$bindir" "$db" -1 -f "$SOCK/extensions.sql" > "$SOCK/extensions.log" 2>&1; then
                CHANGED=true
                # Told to the caller apart from the exit code, which a later failure can replace
                [ -z "${PG_CHANGED_FLAG:-}" ] || touch "$PG_CHANGED_FLAG"
            else
                log "Database $db: the extensions could not be updated"
                grep -v INFO: "$SOCK/extensions.log"
                rc=1
            fi
        fi
    done < "$SOCK/databases"
    server "$bindir" "$PGDATA" stop || return 1
    return "$rc"
}

# Put the upgraded cluster in place. Renames only, and safe to run again after an interruption
# at any point: READY holds the old major and is removed last.
finish_swap() {
    local old bak
    old="$(cat "$WORK/READY")"
    [ -n "$old" ] || return 1
    bak="$PGDATA.pg$old.bak"
    if [ -d "$PGDATA" ] && [ "$(cat "$PGDATA/PG_VERSION")" = "$old" ]; then
        mv -T "$PGDATA" "$bak" || return 1
        touch "$bak/.retired"
        log "The PostgreSQL $old cluster is kept in $bak for $KEEP_DAYS days"
    fi
    if [ ! -d "$PGDATA" ]; then
        mv -T "$WORK/new" "$PGDATA" || return 1
    fi
    # The work directory only goes once the upgraded cluster really is the one in place
    [ "$(cat "$PGDATA/PG_VERSION")" = "$NEW" ] || return 1
    echo "${BUILD_VERSION:-}" > "$STAMP"
    sync
    rm -rf "$WORK" "$FAILED"
}

# Clusters left by a previous upgrade are removed once they are $KEEP_DAYS days old
expire_backups() {
    local bak
    for bak in "$PGDATA".pg*.bak; do
        [ -d "$bak" ] || continue
        [ -f "$bak/.retired" ] || touch "$bak/.retired"
        if [ -n "$(find "$bak/.retired" -mmin +$((KEEP_DAYS * 1440)))" ]; then
            log "Removing $bak, the cluster from before the upgrade more than $KEEP_DAYS days ago"
            rm -rf "$bak"
        else
            log "$bak ($(du -sh "$bak" | cut -f1)) is the cluster from before the upgrade. It is removed at the first start of the add-on $KEEP_DAYS days after the upgrade, or delete it now to free the space"
        fi
    done
}

upgrade() {
    local old="$1" ob="$BIN/$1/bin" nb="$BIN/$NEW/bin" need avail datadir db initdb_args file

    # cp keeps a symlink a symlink: a tablespace or a WAL directory outside the cluster would
    # be shared by the copy and the original
    if [ -n "$(find "$PGDATA" -type l -print -quit)" ]; then
        log "The cluster uses tablespaces or a WAL directory outside $PGDATA, which this upgrade does not handle"
        return 1
    fi

    need="$(du -sk "$PGDATA" | cut -f1)"
    avail="$(df -Pk "$WORK" | awk 'NR==2 {print $4}')"
    if [ "$avail" -lt $((need + need / 10)) ]; then
        log "Not enough free space: the cluster is $((need / 1024)) MB and only $((avail / 1024)) MB are free"
        return 1
    fi

    log "Copying the cluster ($((need / 1024)) MB) to $WORK/old"
    cp -a --reflink=auto "$PGDATA" "$WORK/old" || return 1

    # The copy's own configuration must not point anywhere else, the live directory least of all
    datadir="$("${AS_PG[@]}" "$ob/postgres" -D "$WORK/old" -C data_directory)" || return 1
    if [ "$datadir" != "$WORK/old" ]; then
        log "The cluster's configuration sets data_directory to $datadir: remove that line"
        return 1
    fi

    initdb_args=(-U "$SUPERUSER" -D "$WORK/new")
    if [ "$("${AS_PG[@]}" "$ob/pg_controldata" "$WORK/old" | sed -n 's/^Data page checksum version: *//p')" != 0 ]; then
        initdb_args+=(--data-checksums)
    elif [ "$NEW" -ge 18 ]; then
        initdb_args+=(--no-data-checksums)
    fi
    "${AS_PG[@]}" "$nb/initdb" "${initdb_args[@]}" > "$SOCK/initdb.log" 2>&1 || return 1

    log "Running pg_upgrade $old -> $NEW"
    set -- -b "$ob" -B "$nb" -d "$WORK/old" -D "$WORK/new" -U "$SUPERUSER" -p "$PORT" -P "$PORT" \
        --socketdir "$SOCK" -o "$SERVER_OPTS" -O "$SERVER_OPTS" --link
    (cd "$WORK" && "${AS_PG[@]}" "$nb/pg_upgrade" "$@" --check && "${AS_PG[@]}" "$nb/pg_upgrade" "$@") > "$SOCK/pg_upgrade.log" 2>&1 || return 1

    # The cluster keeps its own settings and access rules. They are in place before the new
    # server is tried, so that a setting the new major no longer knows fails here
    for file in postgresql.conf postgresql.auto.conf postgresql.override.conf pg_hba.conf pg_ident.conf; do
        [ ! -f "$WORK/old/$file" ] || cp -p "$WORK/old/$file" "$WORK/new/$file" || return 1
    done

    # Started with the configuration the add-on starts it with, pointed at the new cluster
    log "Starting PostgreSQL $NEW to check the upgraded cluster"
    sed "s@##PGDATA@$WORK/new@" "/var/postgresql-conf-tpl/postgresql.$(tr '[:upper:]' '[:lower:]' <<< "${DB_STORAGE_TYPE:-SSD}").conf" > "$SOCK/postgresql.conf" || return 1
    # The template includes the override file that sits next to it
    ln -s /etc/postgresql/postgresql.override.conf "$SOCK/postgresql.override.conf"
    SERVER_OPTS="-c config_file=$SOCK/postgresql.conf $SERVER_OPTS"
    server "$nb" "$WORK/new" start || return 1
    while IFS= read -r db; do
        q "$nb" "$db" -c "SELECT 1" > /dev/null || return 1
    done < "$SOCK/databases"
    server "$nb" "$WORK/new" stop || return 1

    echo "$old" > "$WORK/READY" || return 1
    sync
    # From here on the work directory holds the cluster: a failure must not reach its clean-up
    finish_swap || { log "Could not put the upgraded cluster in place"; exit 2; }
}

main() {
    local old

    if [ -f "$WORK/READY" ]; then
        log "Finishing the upgrade that was interrupted"
        finish_swap || { log "Could not put the upgraded cluster in place"; exit 2; }
        exit 10
    fi
    rm -rf "$WORK"

    [ -s "$PGDATA/PG_VERSION" ] || exit 0
    old="$(cat "$PGDATA/PG_VERSION")"
    if [ "$old" -gt "$NEW" ]; then
        log "The data in $PGDATA is from PostgreSQL $old, which is newer than this add-on (PostgreSQL $NEW). Update the add-on, or restore a backup taken with this version"
        exit 2
    fi
    if [ ! -x "$BIN/$old/bin/postgres" ]; then
        log "The data in $PGDATA is from PostgreSQL $old. This add-on can only upgrade from: $(find "$BIN" -mindepth 1 -maxdepth 1 -printf '%f\n' | grep -vx "$NEW" | sort | tr '\n' ' ')"
        exit 2
    fi
    if [ "$old" = "$NEW" ]; then
        expire_backups
        # The libraries of the extensions change with the image, never between two starts of it
        [ "$(cat "$STAMP" 2> /dev/null)" != "${BUILD_VERSION:-}" ] || exit 0
    elif [ -f "$FAILED" ] && [ "$(head -n 1 "$FAILED")" = "${BUILD_VERSION:-}" ]; then
        log "The upgrade from PostgreSQL $old to $NEW already failed with this add-on version, it is not tried again. Delete $FAILED to retry"
        exit 1
    elif [ -e "$PGDATA.pg$old.bak" ]; then
        log "$PGDATA.pg$old.bak already exists, remove it first"
        exit 1
    fi

    SOCK="$(mktemp -d)"
    if [ "$(id -u)" = 0 ]; then
        # A cluster copied in with a file browser belongs to whoever copied it
        find "$PGDATA" \! -user postgres -exec chown postgres '{}' +
        chown postgres "$SOCK"
    fi
    SERVER_OPTS="-c listen_addresses='' -c unix_socket_directories='$SOCK' -c port=$PORT"
    [ ! -f "$BIN/$NEW/lib/vchord.so" ] || SERVER_OPTS="$SERVER_OPTS -c shared_preload_libraries=vchord.so"

    # pg_upgrade restores the extensions at the version the old cluster has them, against the
    # libraries of the new major, which only know the newest. So they are updated first, by the
    # server of the old major, whose libraries in this image are of that same version
    log "Checking the extensions of the PostgreSQL $old cluster"
    if ! update_extensions "$old"; then
        tail -n 15 "$SOCK/server.log" 2> /dev/null
        "${AS_PG[@]}" "$BIN/$old/bin/pg_ctl" -D "$PGDATA" -m fast stop > /dev/null 2>&1
        [ "$old" != "$NEW" ] || exit 11
        log "The upgrade to PostgreSQL $NEW is not tried with extensions that could not be updated"
        exit 1
    fi
    echo "${BUILD_VERSION:-}" > "$STAMP"
    if [ "$old" = "$NEW" ]; then
        "$CHANGED" && exit 10
        exit 0
    fi

    log "The data in $PGDATA is from PostgreSQL $old, upgrading it to $NEW"
    mkdir -p "$WORK" && chown --reference="$PGDATA" "$WORK" && chmod 700 "$WORK" || exit 1
    if upgrade "$old"; then
        log "Upgrade to PostgreSQL $NEW completed and checked"
        exit 10
    fi

    # Whatever is still running on the copy is stopped before it goes
    "${AS_PG[@]}" "$BIN/$NEW/bin/pg_ctl" -D "$WORK/new" -m immediate stop > /dev/null 2>&1
    rm -rf "$LOGS"
    mkdir -p "$LOGS"
    cp -r "$SOCK"/*.log "$WORK"/new/pg_upgrade_output.d "$LOGS"/ 2> /dev/null
    log "Upgrade from PostgreSQL $old to $NEW FAILED. Last lines of the logs, kept in $LOGS:"
    tail -n 15 "$LOGS"/pg_upgrade.log "$LOGS"/server.log 2> /dev/null
    find "$LOGS/pg_upgrade_output.d" -name '*.log' -exec grep -hiE 'error|fatal' {} + 2> /dev/null | head -n 15
    rm -rf "$WORK"
    printf '%s\nPostgreSQL %s -> %s on %s\n' "${BUILD_VERSION:-}" "$old" "$NEW" "$(date)" > "$FAILED"
    exit 1
}

main
