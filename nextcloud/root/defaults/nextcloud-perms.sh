#!/bin/bash

ocpath="${NEXTCLOUD_PATH}"
htuser='abc'
htgroup='abc'
rootuser='root'

printf "Creating possible missing Directories\n"
mkdir -p $ocpath/data
mkdir -p $ocpath/assets
mkdir -p $ocpath/updater
mkdir -p $ocpath/apps
mkdir -p $ocpath/assets
mkdir -p $ocpath/config
mkdir -p $ocpath/data
mkdir -p $ocpath/themes
mkdir -p /data/config/nextcloud/config
mkdir -p /data/config/nextcloud/data
mkdir -p /data/config/www/nextcloud/occ
mkdir -p /share/nextcloud
mkdir -p /ssl/nextcloud/keys

printf "chmod Files and Directories\n"
#chmod -R 777 ${ocpath}
find ${ocpath}/ -type f -exec chmod 0640 {} \;
find ${ocpath}/ -type d -exec chmod 0750 {} \;

#find ${ocpath}/ -type f -print0 | xargs -0 chmod 0640
#find ${ocpath}/ -type d -print0 | xargs -0 chmod 0750

printf "chown Directories\n"
chown -R ${rootuser}:${htgroup} ${ocpath}/
chown -R ${htuser}:${htgroup} ${ocpath}/apps/
chown -R ${htuser}:${htgroup} ${ocpath}/assets/
chown -R ${htuser}:${htgroup} ${ocpath}/config/
chown -R ${htuser}:${htgroup} ${ocpath}/data/
chown -R ${htuser}:${htgroup} ${ocpath}/themes/
chown -R ${htuser}:${htgroup} ${ocpath}/updater/
chown -R ${htuser}:${htgroup} /share/nextcloud
chown -R ${htuser}:${htgroup} /ssl/nextcloud/keys

chmod +x ${ocpath}/occ

printf "chmod/chown .htaccess\n"
if [ -f ${ocpath}/.htaccess ]
 then
  chmod 0644 ${ocpath}/.htaccess
  chown ${rootuser}:${htgroup} ${ocpath}/.htaccess
fi
if [ -f ${ocpath}/data/.htaccess ]
 then
  chmod 0644 ${ocpath}/data/.htaccess
  chown ${rootuser}:${htgroup} ${ocpath}/data/.htaccess
fi
