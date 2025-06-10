#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

####################################
# Clean nginx files at each reboot #
####################################

echo "Cleaning files"
for var in /data/config/nginx /data/config/crontabs /data/config/logs; do
	if [ -d "$var" ]; then rm -r "$var"; fi
done

########################
# Settings permissions #
########################

ocpath="${NEXTCLOUD_PATH}"
htuser='abc'
htgroup='abc'
rootuser='root'

printf "Creating possible missing Directories\n"
for folder in "$ocpath"/data "$ocpath"/assets "$ocpath"/updater "$ocpath"/apps "$ocpath"/assets "$ocpath"/config "$ocpath"/data "$ocpath"/themes /data/config/nextcloud/config /data/config/nextcloud/data /ssl/nextcloud/keys; do
	if [ ! -d "$folder" ]; then
		echo "... $folder"
		mkdir -p "$folder" || true
	fi
done

printf "chmod Files and Directories.  This could take some time, please wait...\n"
#chmod -R 777 "${ocpath}"
find "${ocpath}"/ -type f -exec chmod 0640 {} \;
find "${ocpath}"/ -type d -exec chmod 0750 {} \;

#find "${ocpath}"/ -type f -print0 | xargs -0 chmod 0640
#find "${ocpath}"/ -type d -print0 | xargs -0 chmod 0750

printf "chown Directories. This could take some time, please wait...\n"
chown -R ${rootuser}:${htgroup} "${ocpath}"/
for folder in "${ocpath}"/apps/ "${ocpath}"/assets/ "${ocpath}"/config/ "${ocpath}"/data/ "${ocpath}"/themes/ /ssl/nextcloud/keys; do
	chown -R ${htuser}:${htgroup} "$folder" || true
done

printf "chmod/chown .htaccess\n"

if [ -f "${ocpath}"/.htaccess ]; then
	chmod 0644 "${ocpath}"/.htaccess
	chown "${rootuser}":"${htgroup}" "${ocpath}"/.htaccess
fi

if [ -f "${ocpath}"/data/.htaccess ]; then
	chmod 0644 "${ocpath}"/data/.htaccess
	chown "${rootuser}":"${htgroup}" "${ocpath}"/data/.htaccess
fi
