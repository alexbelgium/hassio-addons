#!/bin/sh

exec misc/tor/start-tor.sh &
./run &
echo "Starting NGinx..."

exec nginx
