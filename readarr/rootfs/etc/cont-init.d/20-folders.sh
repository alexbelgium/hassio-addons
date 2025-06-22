#!/bin/bash

if [ ! -d /share/storage/ebook ]; then
	echo "Creating /share/storage/ebook"
	mkdir -p /share/storage/ebook
	chown -R "$PUID:$PGID" /share/storage/ebook
fi

if [ ! -d /share/downloads ]; then
	echo "Creating /share/downloads"
	mkdir -p /share/downloads
	chown -R "$PUID:$PGID" /share/downloads
fi

if [ -d /config/readarr ] && [ ! -d /config/addons_config/readarr ]; then
	echo "Moving to new location /config/addons_config/readarr"
	mkdir -p /config/addons_config/readarr
	chown -R "$PUID:$PGID" /config/addons_config/readarr
	mv /config/readarr/* /config/addons_config/readarr/
	rm -r /config/readarr
fi

if [ ! -d /config/addons_config/readarr ]; then
	echo "Creating /config/addons_config/readarr"
	mkdir -p /config/addons_config/readarr
	chown -R "$PUID:$PGID" /config/addons_config/readarr
fi

if [ -d /config/addons_config/readarr/readarr ]; then
	mv /config/addons_config/readarr/readarr/{.,}* /config/addons_config/readarr/
	rmdir /config/addons_config/readarr/readarr
fi
