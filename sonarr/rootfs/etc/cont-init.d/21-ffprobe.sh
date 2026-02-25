#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Sonarr v4 looks for ffprobe in its own binary directory (/app/sonarr/bin/)
# via GlobalFFOptions.Configure(options => options.BinaryFolder = AppDomain.CurrentDomain.BaseDirectory)
# Symlink the system-installed ffprobe there so Sonarr can find a working copy

if [ -f /usr/bin/ffprobe ] && [ -d /app/sonarr/bin ]; then
    ln -sf /usr/bin/ffprobe /app/sonarr/bin/ffprobe
    echo "Symlinked /usr/bin/ffprobe to /app/sonarr/bin/ffprobe"
fi
