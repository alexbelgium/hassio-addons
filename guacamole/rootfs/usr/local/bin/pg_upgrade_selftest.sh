#!/usr/bin/env bash
# shellcheck shell=bash
#
# Run by the image build: for every older PostgreSQL major the image ships, create a cluster
# the way upstream does, load the Guacamole schema with a connection, upgrade it with the
# script the add-on runs at startup and read the connection back. Packages that no longer fit
# together fail the build instead of the database of whoever updates first.
set -euo pipefail

export PGDATA=/tmp/selftest/postgres
read -r -a AS_PG <<< "${PG_UPGRADE_RUNAS-/command/s6-setuidgid postgres}"
SQL="SELECT connection_name FROM guacamole_connection"

for bindir in /usr/lib/postgresql/*/bin; do
    old="$(basename "$(dirname "$bindir")")"
    [ "$old" != "$PG_MAJOR" ] || continue
    echo "Self-test: upgrade of a PostgreSQL $old cluster to $PG_MAJOR"

    rm -rf /tmp/selftest
    mkdir -p /tmp/selftest
    [ "$(id -u)" != 0 ] || chown postgres /tmp/selftest
    "${AS_PG[@]}" "$bindir/initdb" -D "$PGDATA" > /dev/null
    "${AS_PG[@]}" "$bindir/pg_ctl" -w -D "$PGDATA" -l /tmp/selftest/old.log start > /dev/null \
        -o "-c listen_addresses='' -c unix_socket_directories=/tmp/selftest" \
        || { cat /tmp/selftest/old.log; exit 1; }
    "${AS_PG[@]}" "$bindir/createuser" -h /tmp/selftest guacamole
    "${AS_PG[@]}" "$bindir/createdb" -h /tmp/selftest -O guacamole guacamole_db
    cat /app/guacamole/schema/*.sql | "${AS_PG[@]}" "$bindir/psql" -h /tmp/selftest -U guacamole -d guacamole_db -v ON_ERROR_STOP=1 -q -f -
    "${AS_PG[@]}" "$bindir/psql" -h /tmp/selftest -U guacamole -d guacamole_db -v ON_ERROR_STOP=1 -q \
        -c "INSERT INTO guacamole_connection (connection_name, protocol) VALUES ('selftest', 'rdp')"
    "${AS_PG[@]}" "$bindir/pg_ctl" -w -D "$PGDATA" stop > /dev/null

    rc=0
    /usr/local/bin/pg_major_upgrade.sh || rc=$?
    if [ "$rc" != 10 ] || [ "$(cat "$PGDATA/PG_VERSION")" != "$PG_MAJOR" ]; then
        echo "Self-test FAILED: upgrade from PostgreSQL $old to $PG_MAJOR returned $rc"
        exit 1
    fi
    rc=0
    /usr/local/bin/pg_major_upgrade.sh > /dev/null || rc=$?
    [ "$rc" = 0 ] || { echo "Self-test FAILED: a second start returned $rc"; exit 1; }

    "${AS_PG[@]}" pg_ctl -w -D "$PGDATA" -l /tmp/selftest/new.log start > /dev/null \
        -o "-c listen_addresses='' -c unix_socket_directories=/tmp/selftest" \
        || { cat /tmp/selftest/new.log; exit 1; }
    [ "$("${AS_PG[@]}" psql -h /tmp/selftest -U guacamole -d guacamole_db -AtqX -c "$SQL")" = selftest ]
    "${AS_PG[@]}" pg_ctl -w -D "$PGDATA" stop > /dev/null
done
rm -rf /tmp/selftest
