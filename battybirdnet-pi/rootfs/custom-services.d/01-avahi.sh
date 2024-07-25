#!/usr/bin/with-contenv bashio
# Waiting for dbus
until [[ -e /var/run/dbus/system_bus_socket ]]; do
    sleep 1s
done

echo "Starting service: avahi daemon"
exec \
    avahi-daemon --no-chroot
