#!/usr/bin/env bash
# shellcheck shell=bash
#
# Upgrade the cluster in $PGDATA to the PostgreSQL major of the image ($PG_MAJOR) when it is
# from an older one whose binaries the image ships. Derived from the postgres_15 add-on's
# pg_major_upgrade.sh, without its extension handling (Guacamole uses none) and without ever
# deleting the old cluster.
#
#   exit 0   nothing to do: fresh install, or the cluster is already on $PG_MAJOR
#   exit 10  the cluster was upgraded and is in place
#   exit 1   the upgrade failed: $PGDATA is untouched, serve it with its own major
#   exit 2   $PGDATA must not be served by this image: start nothing on it
#
# The upgrade runs on a copy in $PGDATA.upgrade. $PGDATA itself is never written to: once the
# upgraded copy has been started and holds the same rows as the original, $PGDATA is renamed
# to $PGDATA.pg<old>.<date>.bak and the copy renamed into its place. Plain bash, no bashio: the
# image build runs this as a self-test.
set -uo pipefail

PGDATA="${PGDATA:?PGDATA is not set}"
NEW="${PG_MAJOR:?PG_MAJOR is not set}"
BIN=/usr/lib/postgresql
WORK="$PGDATA.upgrade"
LOGS="$PGDATA.upgrade_logs"
PORT=50432
# Empty in the test harness, where there is no root to drop from
read -r -a AS_PG <<< "${PG_UPGRADE_RUNAS-/command/s6-setuidgid postgres}"
export PGOPTIONS="-c client_min_messages=warning"

log() { echo "[pg_upgrade] $*"; }

# psql against the private server: q <bindir> <database> [psql args]
q() {
    local bindir="$1" db="$2"
    shift 2
    # Through the environment: -d would read a name such as "a=b" as a connection string
    PGDATABASE="$db" "${AS_PG[@]}" "$bindir/psql" -h "$SOCK" -p "$PORT" -U "$SUPERUSER" -v ON_ERROR_STOP=1 -AtqX "$@"
}

# Private server, reachable only through a unix socket in $SOCK and trusting it whatever the
# cluster's own pg_hba.conf says: server <bindir> <datadir> start|stop
server() {
    if [ "$3" = start ]; then
        "${AS_PG[@]}" "$1/pg_ctl" -w -t 3600 -D "$2" -l "$SOCK/server.log" -o "$SERVER_OPTS" start > /dev/null
    else
        "${AS_PG[@]}" "$1/pg_ctl" -w -t 3600 -D "$2" -m fast stop > /dev/null
    fi
}

# Every table of every database with its row count, one "database|table|count" per line
snapshot() {
    local db
    q "$1" template1 -c "SELECT datname FROM pg_database WHERE datallowconn ORDER BY 1" > "$SOCK/databases" || return 1
    while IFS= read -r db; do
        printf '%s\n' "SELECT format('SELECT %L, %L, count(*) FROM %I.%I', current_database(), n.nspname || '.' || c.relname, n.nspname, c.relname)
            FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE c.relkind = 'r' AND n.nspname NOT IN ('pg_catalog', 'information_schema') AND n.nspname NOT LIKE 'pg_toast%'
            ORDER BY 1" '\gexec' | q "$1" "$db" -F '|' || return 1
    done < "$SOCK/databases"
}

# control <major> <datadir> <field>: a field of pg_controldata, empty when it cannot be read
control() {
    "${AS_PG[@]}" "$BIN/$1/bin/pg_controldata" "$2" 2> /dev/null | sed -n "s/^$3: *//p"
}

# Put the upgraded cluster in place. Renames only, safe to run again after an interruption at
# any point: READY names the old major, the system identifier of the upgraded cluster and the
# backup directory, and the work directory only goes once that very cluster is in $PGDATA.
finish_swap() {
    local old id bak
    read -r old id bak < "$WORK/READY" || return 1
    [ -n "$old" ] && [ -n "$id" ] && [ -n "$bak" ] || return 1
    if [ -d "$WORK/new" ] && [ -d "$PGDATA" ] && [ ! -e "$bak" ] && [ "$(cat "$PGDATA/PG_VERSION" 2> /dev/null)" = "$old" ]; then
        mv -T "$PGDATA" "$bak" || return 1
        log "The PostgreSQL $old cluster is kept in $bak"
    fi
    if [ -d "$WORK/new" ] && [ ! -e "$PGDATA" ]; then
        mv -T "$WORK/new" "$PGDATA" || return 1
    fi
    # Anything else in $PGDATA (a cluster created meanwhile, the old one put back) stops here,
    # with both copies kept
    if [ -e "$WORK/new" ] || [ "$(cat "$PGDATA/PG_VERSION" 2> /dev/null)" != "$NEW" ] || [ "$(control "$NEW" "$PGDATA" "Database system identifier")" != "$id" ]; then
        return 1
    fi
    sync
    rm -rf "$WORK"
}

upgrade() {
    local old="$1" ob="$BIN/$1/bin" nb="$BIN/$NEW/bin" need avail datadir file id setting old_opts="$SERVER_OPTS"
    local -a initdb_args

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
    rm -f "$WORK/old/postmaster.pid"

    # The copy's own configuration must not point anywhere else, the live directory least of all
    datadir="$("${AS_PG[@]}" "$ob/postgres" -D "$WORK/old" -C data_directory)" || return 1
    if [ "$datadir" != "$WORK/old" ]; then
        log "The cluster's configuration sets data_directory to $datadir: remove that line"
        return 1
    fi
    # Bootstrap superuser, which pg_upgrade and initdb need by name
    SUPERUSER="$("${AS_PG[@]}" "$ob/postgres" --single -D "$WORK/old" template1 <<< "SELECT rolname FROM pg_authid WHERE oid = 10" 2> /dev/null \
        | sed -n 's/.*rolname = "\(.*\)".*/\1/p')"
    [ -n "$SUPERUSER" ] || { log "Could not read the superuser of the cluster"; return 1; }

    # Up to PostgreSQL 14 the statistics files go wherever stats_temp_directory says
    [ "$old" -gt 14 ] || old_opts="$old_opts -c stats_temp_directory=pg_stat_tmp"
    # The old server on the copy: recovers it if it was not shut down cleanly, and counts its rows
    SERVER_OPTS="$old_opts" server "$ob" "$WORK/old" start || return 1
    snapshot "$ob" > "$SOCK/rows.before" || return 1
    mapfile -t initdb_args < <(q "$ob" template1 -c "SELECT unnest(ARRAY['--encoding=' || pg_encoding_to_char(encoding), '--lc-collate=' || datcollate, '--lc-ctype=' || datctype]) FROM pg_database WHERE datname = 'template1'")
    [ "${#initdb_args[@]}" = 3 ] || return 1
    SERVER_OPTS="$old_opts" server "$ob" "$WORK/old" stop || return 1

    initdb_args+=(-U "$SUPERUSER" -D "$WORK/new")
    [ "$(control "$old" "$WORK/old" "Data page checksum version")" = 0 ] || initdb_args+=(--data-checksums)
    "${AS_PG[@]}" "$nb/initdb" "${initdb_args[@]}" > "$SOCK/initdb.log" 2>&1 || return 1

    log "Running pg_upgrade $old -> $NEW"
    set -- -b "$ob" -B "$nb" -d "$WORK/old" -D "$WORK/new" -U "$SUPERUSER" -p "$PORT" -P "$PORT" \
        --socketdir "$SOCK" -o "$old_opts" -O "$SERVER_OPTS" --link
    (cd "$WORK" && "${AS_PG[@]}" "$nb/pg_upgrade" "$@") > "$SOCK/pg_upgrade.log" 2>&1 || return 1

    # The cluster keeps its own settings, access rules and the files they include. They are in
    # place before the new server is tried, so that a setting the new major no longer knows
    # fails here and not after the swap
    for file in "$WORK"/old/*.conf; do
        [ ! -f "$file" ] || cp -p "$file" "$WORK/new/" || return 1
    done

    log "Starting PostgreSQL $NEW to check the upgraded cluster"
    server "$nb" "$WORK/new" start || return 1
    # Every file the configuration uses must be where the same path finds it after the swap: in
    # the upgraded cluster or outside the old directory, which is renamed. The server lists the
    # files it read (includes resolved, comments ignored); it runs with its own access rules, so
    # the cluster's are asked for separately
    q "$nb" template1 -c "SELECT DISTINCT sourcefile FROM pg_file_settings WHERE sourcefile IS NOT NULL" > "$SOCK/files" || return 1
    for setting in hba_file ident_file; do
        "${AS_PG[@]}" "$nb/postgres" -D "$WORK/new" -C "$setting" >> "$SOCK/files" || return 1
    done
    while IFS= read -r file; do
        if [ ! -f "$file" ] || { [[ "$file" == "$PGDATA/"* ]] && [ ! -f "$WORK/new/${file#"$PGDATA/"}" ]; }; then
            log "The cluster's configuration uses $file, which would not be found after the upgrade: name it *.conf directly in $PGDATA, or keep it outside"
            return 1
        fi
    done < "$SOCK/files"
    # Indexes on text are rebuilt in case the collation of the C library changed since they were
    # built, and the planner statistics, which pg_upgrade does not carry over, are collected
    "${AS_PG[@]}" "$nb/reindexdb" --all -h "$SOCK" -p "$PORT" -U "$SUPERUSER" -q > "$SOCK/reindex.log" 2>&1 || return 1
    "${AS_PG[@]}" "$nb/vacuumdb" --all --analyze-only -h "$SOCK" -p "$PORT" -U "$SUPERUSER" -q > "$SOCK/vacuum.log" 2>&1 || return 1
    snapshot "$nb" > "$SOCK/rows.after" || return 1
    server "$nb" "$WORK/new" stop || return 1
    LC_ALL=C sort -o "$SOCK/rows.before" "$SOCK/rows.before" && LC_ALL=C sort -o "$SOCK/rows.after" "$SOCK/rows.after" || return 1
    if ! diff "$SOCK/rows.before" "$SOCK/rows.after" > "$SOCK/rows.diff"; then
        log "The upgraded cluster does not hold the same rows as the original:"
        head -n 20 "$SOCK/rows.diff"
        return 1
    fi
    log "Checked: $(wc -l < "$SOCK/rows.after") tables hold the same number of rows as before"

    id="$(control "$NEW" "$WORK/new" "Database system identifier")"
    [ -n "$id" ] || return 1
    echo "$old $id $PGDATA.pg$old.$(date +%Y%m%d-%H%M%S).bak" > "$WORK/READY" || return 1
    sync
    # From here on the work directory holds the cluster: a failure must not reach its clean-up
    finish_swap || { log "Could not put the upgraded cluster in place, both copies are kept in $PGDATA* directories"; exit 2; }
}

main() {
    local old bak

    if [ -f "$WORK/READY" ]; then
        log "Finishing the upgrade that was interrupted"
        finish_swap || { log "Could not put the upgraded cluster in place, both copies are kept in $PGDATA* directories"; exit 2; }
        exit 10
    fi
    # Without READY the work directory holds only copies: $PGDATA was not touched
    rm -rf "$WORK"

    [ -s "$PGDATA/PG_VERSION" ] || exit 0
    old="$(cat "$PGDATA/PG_VERSION")"
    if [ "$old" = "$NEW" ]; then
        for bak in "$PGDATA".pg*.bak; do
            [ -d "$bak" ] || continue
            log "$bak is the database from before an upgrade of PostgreSQL. Delete it once you have checked that everything is there"
        done
        exit 0
    fi
    if [[ ! "$old" =~ ^[0-9]+$ ]] || [ "$old" -gt "$NEW" ]; then
        log "The data in $PGDATA is from PostgreSQL $old, which is newer than this add-on (PostgreSQL $NEW). Update the add-on, or restore a backup taken with this version"
        exit 2
    fi
    if [ ! -x "$BIN/$old/bin/postgres" ]; then
        log "The data in $PGDATA is from PostgreSQL $old, which this add-on cannot upgrade. It can upgrade from: $(find "$BIN" -mindepth 1 -maxdepth 1 -printf '%f\n' | grep -vx "$NEW" | sort | tr '\n' ' ')"
        exit 2
    fi

    log "The data in $PGDATA is from PostgreSQL $old, upgrading it to $NEW"
    SOCK="$(mktemp -d)"
    # Nothing the cluster's own settings send elsewhere (logs, WAL archive) runs on a copy
    SERVER_OPTS="-c listen_addresses='' -c unix_socket_directories='$SOCK' -c port=$PORT -c hba_file='$SOCK/pg_hba.conf' -c archive_mode=off -c logging_collector=off -c external_pid_file=''"
    echo "local all all trust" > "$SOCK/pg_hba.conf"
    mkdir -p "$WORK" && chmod 700 "$WORK" "$SOCK" || exit 1
    if [ "$(id -u)" = 0 ]; then
        chown --reference="$PGDATA" "$WORK" && chown postgres "$SOCK" "$SOCK/pg_hba.conf" || exit 1
    fi
    if upgrade "$old"; then
        rm -rf "$SOCK"
        log "Upgrade to PostgreSQL $NEW completed and checked"
        exit 10
    fi

    # Whatever still runs on the copies is stopped before they go
    "${AS_PG[@]}" "$BIN/$NEW/bin/pg_ctl" -D "$WORK/new" -m immediate stop > /dev/null 2>&1
    "${AS_PG[@]}" "$BIN/$old/bin/pg_ctl" -D "$WORK/old" -m immediate stop > /dev/null 2>&1
    rm -rf "$LOGS"
    mkdir -p "$LOGS"
    cp -r "$SOCK"/*.log "$WORK"/new/pg_upgrade_output.d "$LOGS"/ 2> /dev/null
    log "Upgrade from PostgreSQL $old to $NEW FAILED, $PGDATA was not changed. Last lines of the logs, kept in $LOGS:"
    tail -n 15 "$LOGS"/pg_upgrade.log "$LOGS"/server.log 2> /dev/null
    find "$LOGS/pg_upgrade_output.d" -name '*.log' -exec grep -hiE 'error|fatal' {} + 2> /dev/null | head -n 15
    rm -rf "$WORK" "$SOCK"
    exit 1
}

main
