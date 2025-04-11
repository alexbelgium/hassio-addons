#!/bin/sh
# shellcheck disable=SC2013,SC2016,SC2236
set -e

#############################
# Modify global lsio images #
#############################

# Set variable
CONFIGLOCATION="${1:-/config}"
echo "Setting config to $CONFIGLOCATION"

# Avoid custom-init.d duplications
for file in $(grep -sril 'Potential tampering with custom' /etc/cont-init.d /etc/services.d /etc/s6-overlay/s6-rc.d); do
    rm -f "$file"
done

# If custom config
if [ "$CONFIGLOCATION" != "/config" ]; then

    # Create new config folder if needed
    for file in $(grep -srl "PUID" /etc/cont-init.d /etc/s6-overlay/s6-rc.d); do
        sed -i "1a mkdir -p $CONFIGLOCATION" "$file"
    done

    # Correct config location
    for file in $(grep -Esril "/config[ '\"/]|/config\$" /etc /defaults); do
        sed -Ei "s=(/config)+(/| |$|\"|\')=$CONFIGLOCATION\2=g" "$file"
    done

fi

# Allow UID and GID setting
for file in $(grep -srl "PUID" /etc/cont-init.d /etc/s6-overlay/s6-rc.d); do
    sed -i 's/bash/bashio/g' "$file" && sed -i '1a PUID="$(if bashio::config.has_value "PUID"; then bashio::config "PUID"; else echo "0"; fi)"' "$file"
    sed -i '1a PGID="$(if bashio::config.has_value "PGID"; then bashio::config "PGID"; else echo "0"; fi)"' "$file"
done

# Avoid chmod /config if ha config mounted
if [ -f /config/configuration.yaml ] || [ -f /config/configuration.json ]; then
    for file in /etc/services.d/*/* /etc/cont-init.d/* /etc/s6-overlay/s6-rc.d/*/*; do
        if [ -f "$file" ] && [ -n "$(awk '/chown.*abc:abc.*\\/,/.*\/config( |$)/{print FILENAME}' "$file")" ]; then
            sed -i "s|/config$|/data|g" "$file"
        fi
    done
fi

# Send crond logs to addon logs
if [ -f /etc/s6-overlay/s6-rc.d/svc-cron/run ]; then
    sed -i "/exec busybox crond/c exec busybox crond -f -S -L /proc/1/fd/1" /etc/s6-overlay/s6-rc.d/svc-cron/run
    sed -i "/exec \/usr\/sbin\/cron/c exec /usr/sbin/cron -f &>/proc/1/fd/1" /etc/s6-overlay/s6-rc.d/svc-cron/run
fi

# variables not found
for file in $(grep -srl "/usr/bin" /etc/cont-init.d /etc/s6-overlay/s6-rc.d); do
    sed -i "1a set +u" "$file"
done

# Allow running abc as user 1
sed -i '/\(usermod\|groupmod\)/{/2>\/dev\/null/!s/$/ 2>\/dev\/null/;}' "$1" /etc/s6-overlay/s6-rc.d/init-adduser/run

# Replace lsiown if not found
if [ ! -f /usr/bin/lsiown ]; then
    for file in $(grep -sril "lsiown" /etc); do
        sed -i "s|lsiown|chown|g" "$file"
    done
fi
