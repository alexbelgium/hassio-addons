#!/bin/sh
# shellcheck disable=SC2013,SC2016,SC2236
set -e

#############################
# Modify global lsio images #
#############################

# Set variable
CONFIGLOCATION="$1"
echo "Setting config to $CONFIGLOCATION"

# Avoid custom-init.d duplications
for file in $(grep -sril 'Potential tampering with custom' /etc/cont-init.d /etc/services.d /etc/s6-overlay/s6-rc.d); do
    rm -f "$file"
done

# Create new config folder if needed
for file in $(grep -srl "PUID" /etc/cont-init.d /etc/s6-overlay/s6-rc.d); do
    sed -i "1a mkdir -p $CONFIGLOCATION" "$file"
done

# Allow UID and GID setting
for file in $(grep -srl "PUID" /etc/cont-init.d /etc/s6-overlay/s6-rc.d); do
    sed -i 's/bash/bashio/g' "$file" && sed -i '1a PUID="$(if bashio::config.has_value "PUID"; then bashio::config "PUID"; else echo "0"; fi)"' "$file"
    sed -i '1a PGID="$(if bashio::config.has_value "PGID"; then bashio::config "PGID"; else echo "0"; fi)"' "$file"
done

# Correct config location
for file in $(grep -Esril "/config[ '\"/]|/config\$" /etc /defaults); do
    sed -Ei "s=(/config)+(/| |$|\"|\')=$CONFIGLOCATION\2=g" "$file"
done

# Avoid chmod /config
for file in /etc/services.d/*/* /etc/cont-init.d/* /etc/s6-overlay/s6-rc.d/*/*; do
    if [ -f "$file" ] && [ ! -z "$(awk '/chown.*abc:abc.*\\/,/.*\/config( |$)/{print FILENAME}' "$file")" ]; then
        sed -i "s|/config$|/data|g" "$file"
    fi
done

# Send crond logs to addon logs
if [ -f /etc/s6-overlay/s6-rc.d/svc-cron/run ]; then
    sed -i "/exec busybox crond/c exec busybox crond -f -L /proc/1/fd/1 -S" /etc/s6-overlay/s6-rc.d/svc-cron/run
    sed -i "/exec \/usr\/sbin\/cron/c exec /usr/sbin/cron -f -L /proc/1/fd/1 5" /etc/s6-overlay/s6-rc.d/svc-cron/run
fi

# Replace lsiown if not found
if [ ! -f /usr/bin/lsiown ]; then
    for file in $(grep -sril "lsiown" /etc); do
        sed -i "s|lsiown|chown|g" "$file"
    done
fi
