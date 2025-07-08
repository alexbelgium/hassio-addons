#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

##################
# SELECT FOLDERS #
##################

#Set media dir
MEDIADIR=$(bashio::config 'storage_dir')
#clean data
sed -i '/MEDIA_DIR/d' /data/config/papermerge.conf.py
#add data
sed -i "2 i\MEDIA_DIR = \"$MEDIADIR\"" /data/config/papermerge.conf.py
bashio::log.info "Storage dir set to $MEDIADIR"

#Set import dir
IMPORTDIR=$(bashio::config 'import_dir')
#clean data
sed -i '/IMPORTER_DIR/d' /data/config/papermerge.conf.py || true
#add data
sed -i "2 i\IMPORTER_DIR = \"$IMPORTDIR\"" /data/config/papermerge.conf.py
bashio::log.info "Import dir set to $IMPORTDIR"

##################
# CREATE FOLDERS #
##################

#if [ ! -d /data/config ]; then
#    echo "Creating /config"
#    mkdir -p /config
#fi
#chown -R "$PUID:$PGID" /config

if [ ! -d "$MEDIADIR" ]; then
	echo "Creating $MEDIADIR"
	mkdir -p "$MEDIADIR"
fi
chown -R "$PUID:$PGID" "$MEDIADIR"

if [ ! -d "$IMPORTDIR" ]; then
	echo "Creating $IMPORTDIR"
	mkdir -p "$IMPORTDIR"
fi
chown -R "$PUID:$PGID" "$IMPORTDIR"

##################
# CONFIGURE IMAP #
##################

IMAPHOST=$(bashio::config 'imaphost')
IMAPUSERNAME=$(bashio::config 'imapusername')
IMAPPASSWORD=$(bashio::config 'imappassword')

if [ "$IMAPHOST" != "null" ]; then
	printf "\nIMPORT_MAIL_HOST = \"%s\"" "$IMAPHOST" >>/data/config/papermerge.conf.py
	bashio::log.info "IMPORT_MAIL_HOST set to $IMAPHOST"

	if [ "$IMAPUSERNAME" != "null" ]; then
		printf "\nIMPORT_MAIL_USER = \"%s\"" "$IMAPUSERNAME" >>/data/config/papermerge.conf.py
		bashio::log.info "IMPORT_MAIL_USER set to $IMAPUSERNAME"
	else
		bashio::log.info "! IMAPHOST has been set, but no IMAPUSERNAME. Please check your configuration!"
	fi

	if [ "$IMAPPASSWORD" != "null" ]; then
		printf "\nIMPORT_MAIL_PASS = \"%s\"" "$IMAPPASSWORD" >>/data/config/papermerge.conf.py
		IMAPPASSWORDMASKED=$(echo "$IMAPPASSWORD" | sed -r 's/./x/g')
		bashio::log.info "IMPORT_MAIL_PASS set to $IMAPPASSWORDMASKED"
	else
		bashio::log.info "! IMAPHOST has been set, but no IMAPPASSWORD. Please check your configuration!"
	fi

fi
