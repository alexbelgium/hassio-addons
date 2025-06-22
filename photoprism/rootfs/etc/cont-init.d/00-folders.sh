#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

if bashio::config.has_value "PUID" && bashio::config.has_value "PGID"; then
	PUID="$(bashio::config "PUID")"
	PGID="$(bashio::config "PGID")"
	bashio::log.green "Setting user to $PUID:$PGID"
	id -u photoprism &>/dev/null || usermod -o -u "$PUID" photoprism || true
	id -g photoprism &>/dev/null || groupmod -o -g "$PGID" photoprism || true
fi

bashio::log.info "Preparing scripts"
echo "... creating structure"
mkdir -p \
	/data/photoprism/originals \
	/data/photoprism/import \
	/data/photoprism/storage/config \
	/data/photoprism/backup \
	/data/photoprism/storage/cache

echo "... setting permissions"
chmod -R 777 /data/photoprism
chown -Rf photoprism:photoprism /data/photoprism
chmod -Rf a+rwx /data/photoprism
for line in BACKUP_PATH IMPORT_PATH ORIGINALS_PATH STORAGE_PATH; do
	mkdir -p "$line"
	chmod -R 777 "$line"
	chown -Rf photoprism:photoprism "$line"
done
