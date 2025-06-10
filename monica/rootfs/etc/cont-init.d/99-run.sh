#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# Set structure #
#################

mkdir -p /config/storage
cp -rf /var/www/html/storage/* /config/storage/
rm -r /var/www/html/storage
ln -sf /config/storage /var/www/html/storage
chown -R www-data:www-data /config

###################
# Define database #
###################

database="$(bashio::config 'database')"
bashio::log.info "Data selected : $database"

case "$database" in

# Use sqlite
sqlite)
	DB_DATABASE="/config/database.sqlite"
	export DB_DATABASE
	DB_CONNECTION=sqlite
	export DB_CONNECTION
	touch "$DB_DATABASE"
	mkdir -p /var/www/html/database
	ln -sf "$DB_DATABASE" /var/www/html/database/database.sqlite
	chown www-data:www-data "$DB_DATABASE"
	bashio::log.blue "Using $DB_DATABASE"
	;;

# Use Mariadb_addon
MariaDB_addon)
	# Use MariaDB
	DB_CONNECTION=mysql
	export DB_CONNECTION
	bashio::log.green "Using MariaDB addon. Requirements: running MariaDB addon. Discovering values..."
	if ! bashio::services.available 'mysql'; then
		bashio::log.fatal "Local database access should be provided by the MariaDB addon"
		bashio::exit.nok "Please ensure it is installed and started"
	fi

	# Use values
	DB_HOST=$(bashio::services "mysql" "host") && bashio::log.blue "DB_HOST=$DB_HOST" && sed -i "1a export DB_HOST=$DB_HOST" /usr/local/bin/entrypoint.sh
	DB_PORT=$(bashio::services "mysql" "port") && bashio::log.blue "DB_PORT=$DB_PORT" && sed -i "1a export DB_PORT=$DB_PORT" /usr/local/bin/entrypoint.sh
	DB_DATABASE=monica && bashio::log.blue "DB_DATABASE=$DB_DATABASE" && sed -i "1a export DB_DATABASE=$DB_DATABASE" /usr/local/bin/entrypoint.sh
	DB_USERNAME=$(bashio::services "mysql" "username") && bashio::log.blue "DB_USERNAME=$DB_USERNAME" && sed -i "1a export DB_USERNAME=$DB_USERNAME" /usr/local/bin/entrypoint.sh
	DB_PASSWORD=$(bashio::services "mysql" "password") && bashio::log.blue "DB_PASSWORD=$DB_PASSWORD" && sed -i "1a export DB_PASSWORD=$DB_PASSWORD" /usr/local/bin/entrypoint.sh
	export DB_HOST
	export DB_PORT
	export DB_DATABASE
	export DB_USERNAME
	export DB_PASSWORD

	bashio::log.warning "Monica is using the MariaDB addon"
	bashio::log.warning "Please ensure this is included in your backups"
	bashio::log.warning "Uninstalling the MariaDB addon will remove any data"

	# Create database
	mysql --host="$DB_HOST" --port="$DB_PORT" --user="$DB_USERNAME" --password="$DB_PASSWORD" -e"CREATE DATABASE IF NOT EXISTS $DB_DATABASE;"

	;;

# Use Mariadb_addon
Mysql_external)
	DB_CONNECTION=mysql
	export DB_CONNECTION
	for var in DB_DATABASE DB_HOST DB_PASSWORD DB_PORT DB_USERNAME; do
		# Verify all variables are set
		if ! bashio::config.has_value "$var"; then
			bashio::log.fatal "You have selected to not use the automatic MariaDB detection by manually configuring the addon options, but the option $var is not set."
			exit 1
		fi
		"$var=$(bashio::config "var")"
		export "${var?}"
		bashio::log.blue "$var=$(bashio::config "var")"
	done
	# Alert if MariaDB is available
	if bashio::services.available 'mysql'; then
		bashio::log.warning "The MariaDB addon is available, but you have selected to use your own database by manually configuring the addon options"
	fi

	# Create database
	mysql --host="$DB_HOST" --port="$DB_PORT" --user="$DB_USERNAME" --password="$DB_PASSWORD" -e"CREATE DATABASE IF NOT EXISTS $DB_DATABASE;"

	;;

esac

###########
# APP_KEY #
###########

# Get APP_KEY from bashio::config
APP_KEY=$(bashio::config "APP_KEY")

# Check if APP_KEY is not 32 characters long
if [ -z "$APP_KEY" ] || [ ${#APP_KEY} -lt 32 ]; then
	APP_KEY="$(
		echo -n 'base64:'
		openssl rand -base64 32
	)"
	bashio::addon.option "APP_KEY" "${APP_KEY}"
	bashio::log.warning "The APP_KEY set was invalid, generated a random one: ${APP_KEY}. Restarting to take it into account"
	echo "${APP_KEY}" >>/config/APP_KEY
	bashio::addon.restart
fi
APP_KEY="$(bashio::config "APP_KEY")"
export APP_KEY

bashio::log.info "Starting Monica"

entrypoint.sh apache2-foreground
