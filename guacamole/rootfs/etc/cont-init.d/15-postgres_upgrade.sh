#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

#######################
# Upgrade PostgreSQL  #
#######################

# After 10-migrate.sh, which can bring in a cluster from the old location, and before the
# upstream 40-postgres.sh, which creates a new one wherever /config/postgres has none
rc=0
/usr/local/bin/pg_major_upgrade.sh || rc=$?
case "$rc" in
    0 | 10) ;;
    1)
        old="$(cat /config/postgres/PG_VERSION)"
        bashio::log.warning "The database stays on PostgreSQL $old, unchanged; the upgrade to PostgreSQL $PG_MAJOR is tried again at the next start"
        # The upstream service starts the server of the image's major, which cannot read it
        sed -i "s|/usr/lib/postgresql/\${PG_MAJOR}/|/usr/lib/postgresql/$old/|" /etc/services.d/postgres/run
        ;;
    *)
        bashio::log.fatal "The database in /config/postgres cannot be used by this version of the add-on, see above. Nothing was deleted. Stopping the add-on"
        # PID 1 (ha_entrypoint.sh) stops the container once this script returns, before any
        # service starts or a later script creates an empty database
        kill -TERM 1
        exit 1
        ;;
esac
