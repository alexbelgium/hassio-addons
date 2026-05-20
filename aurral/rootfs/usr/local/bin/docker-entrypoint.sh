#!/bin/sh
# Passthrough entrypoint — s6-overlay (via HA init: false) handles init.
# The upstream entrypoint tries to chown /app/backend/data which fails
# on HA-mounted host paths. We bypass it entirely and use AURRAL_DATA_DIR
# to redirect the data directory instead.
exec "$@"
