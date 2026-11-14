#!/usr/bin/env bash
# shellcheck shell=bash
#
# Run by the image build: for every older PostgreSQL major the image ships, create a cluster
# with a VectorChord index, upgrade it with the script the add-on runs at startup, and read the
# data back. A base image whose pieces no longer fit together fails the build instead of the
# database of whoever updates first.
set -euo pipefail

export PGDATA=/tmp/selftest/database BUILD_VERSION=selftest
read -r -a AS_PG <<< "${PG_UPGRADE_RUNAS-gosu postgres}"
SQL="SELECT count(*) FROM selftest WHERE e <-> '[1,2,3]' < 1"

for bindir in /usr/lib/postgresql/*/bin; do
    old="$(basename "$(dirname "$bindir")")"
    [ "$old" != "$PG_MAJOR" ] || continue
    echo "Self-test: upgrade of a PostgreSQL $old cluster to $PG_MAJOR"

    rm -rf /tmp/selftest
    mkdir -p /tmp/selftest
    [ "$(id -u)" != 0 ] || chown postgres /tmp/selftest
    "${AS_PG[@]}" "$bindir/initdb" -U postgres -D "$PGDATA" > /dev/null

    # Started as the add-on starts a cluster it could not upgrade: the old server with the
    # settings of this image, so those are checked against every major too
    sed "s@##PGDATA@$PGDATA@" /var/postgresql-conf-tpl/postgresql.ssd.conf > /tmp/selftest/postgresql.conf
    "${AS_PG[@]}" "$bindir/pg_ctl" -w -D "$PGDATA" -l /tmp/selftest/old.log start > /dev/null \
        -o "-c config_file=/tmp/selftest/postgresql.conf -c listen_addresses='' -c unix_socket_directories=/tmp/selftest" \
        || { cat /tmp/selftest/old.log; exit 1; }
    "${AS_PG[@]}" "$bindir/psql" -h /tmp/selftest -U postgres -v ON_ERROR_STOP=1 -q \
        -c "SET client_min_messages = warning" \
        -c "CREATE EXTENSION vchord CASCADE" \
        -c "CREATE TABLE selftest (id int, e vector(3))" \
        -c "INSERT INTO selftest SELECT g, ARRAY[g, 2, 3]::real[]::vector FROM generate_series(1, 100) g" \
        -c "CREATE INDEX ON selftest USING vchordrq (e vector_l2_ops)"
    "${AS_PG[@]}" "$bindir/pg_ctl" -w -D "$PGDATA" stop > /dev/null

    rc=0
    /usr/local/bin/pg_major_upgrade.sh || rc=$?
    if [ "$rc" != 10 ] || [ "$(cat "$PGDATA/PG_VERSION")" != "$PG_MAJOR" ]; then
        echo "Self-test FAILED: upgrade from PostgreSQL $old to $PG_MAJOR returned $rc"
        exit 1
    fi

    "${AS_PG[@]}" pg_ctl -w -D "$PGDATA" -l /tmp/selftest/new.log start > /dev/null \
        -o "-c config_file=/tmp/selftest/postgresql.conf -c listen_addresses='' -c unix_socket_directories=/tmp/selftest" \
        || { cat /tmp/selftest/new.log; exit 1; }
    [ "$("${AS_PG[@]}" psql -h /tmp/selftest -U postgres -AtqX -c "$SQL")" = 1 ]
    "${AS_PG[@]}" pg_ctl -w -D "$PGDATA" stop > /dev/null
done
rm -rf /tmp/selftest
