#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Kapowarr keeps its database, its logs and its temporary downloads outside the
# image so that they survive the container being recreated.
#
# The database and log folders are passed on the command line (see
# /etc/services.d/kapowarr/run). The temporary download folder is not: upstream
# re-applies --TempDownloadFolder on every start Kapowarr makes, including the
# self-restarts it performs after a hosting change, so passing it would keep
# undoing a folder the user picked in Settings > Download. Symlinking upstream's
# default onto persistent storage gives the same persistence and leaves the
# setting itself entirely to the user.

CONFIG_LOCATION="/config"
bashio::log.info "Config stored in $CONFIG_LOCATION"

mkdir -p "$CONFIG_LOCATION/logs" "$CONFIG_LOCATION/temp_downloads"

# Compared against the target rather than just testing for a symlink, so that a
# link left pointing somewhere else -- by a future upstream image, or by hand --
# is repaired instead of silently kept.
if [ "$(readlink /app/temp_downloads)" != "$CONFIG_LOCATION/temp_downloads" ]; then
    rm -rf /app/temp_downloads
    ln -s "$CONFIG_LOCATION/temp_downloads" /app/temp_downloads
fi

# Numbered 20- on purpose : it must sort after 00-global_var.sh, which is what
# exports PUID/PGID from the addon options. The upstream image sets both to 0,
# so the fallbacks only apply when the module is absent.
# Recursive because a user raising PUID after the first run would otherwise
# leave Kapowarr.db, its -wal/-shm sidecars and the logs owned by the previous
# uid, which sqlite then cannot write.
chown -R "${PUID:-0}:${PGID:-0}" "$CONFIG_LOCATION"
