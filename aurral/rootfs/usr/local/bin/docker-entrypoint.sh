#!/bin/sh
# Replacement for the upstream docker-entrypoint.sh.
# The upstream version runs chown -R on /app/backend/data which fails when
# that path is a symlink to a host-mounted HA volume (Operation not permitted).
# All setup (symlinks, directory creation) is handled by the s6 run script.
exec "$@"
