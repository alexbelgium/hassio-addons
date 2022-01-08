#!/usr/bin/with-contenv bashio

# Fix mate software center
if [ -f /usr/lib/dbus-1.0/dbus-daemon-launch-helper ]; then
chmod u+s /usr/lib/dbus-1.0/dbus-daemon-launch-helper
service dbus restart
fi

# Enable acceleration
mkdir -p /share/webtop/boot
touch /share/webtop/boot/config.txt
ln -s /share/webtop/boot/config.txt /boot/
