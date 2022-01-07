#!/usr/bin/with-contenv bashio

#create folders
datadirectory=$(bashio::config 'data_directory')
mkdir -p \
	$datadirectory \
	/data/config/nextcloud/config \
	/data/config/nextcloud/data \
        /data/config/www/nextcloud/config

#permissions
chown abc:abc \
	$datadirectory \
	/data/config/nextcloud/config \
	/data/config/nextcloud/data \
        /data/config/www/nextcloud/config
	
chown -R abc:abc  \
	/var/lib/nginx
	
rm -r /data/config/www/nextcloud/assets &>/dev/null
chmod -R 777 /data/config
