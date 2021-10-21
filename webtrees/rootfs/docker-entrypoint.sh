#!/bin/bash

##################
# INITIAL CONFIG #
##################

export PRETTY_URLS=0
export LANG="en-US"
export BASE_URL="http://192.168.178.69:9999"
export DB_TYPE="sqlite"
export DB_HOST="http://127.0.0.1"
export DB_PORT="80"
export DB_USER="test"
export DB_PASS="test"
export DB_NAME="webtrees.sqlite"
export DB_PREFIX="wt_"
export WT_USER="username"
export WT_NAME="Full Name"
export WT_PASS= "mybadpassword"
export WT_EMAIL="me@example.com"

if [ -f /data/config.ini.php ]; then
ln -s /data/config.ini.php /var/www/webtrees/data
fi

if [ -f /data/webtrees.sqlite ]; then
ln -s /data/webtrees.sqlite /var/www/webtrees/data
fi

#############
# START APP #
#############

CONFIG_FILE="data/config.ini.php"
PREFIX="[NV_INIT]"

echo "$PREFIX Setting folder permissions for uploads"
chown -R www-data:www-data data && chmod -R 775 data
chown -R www-data:www-data media && chmod -R 775 media

# Pull environment variables from files

PRETTY_URLS=$(cat "$PRETTY_URLS_FILE" 2> /dev/null || echo $PRETTY_URLS)
HTTPS=$(cat "$HTTPS_FILE" 2> /dev/null || echo $HTTPS)
SSL=$(cat "$SSL_FILE" 2> /dev/null || echo $SSL)
HTTPS_REDIRECT=$(cat "$HTTPS_REDIRECT_FILE" 2> /dev/null || echo $HTTPS_REDIRECT)
SSL_REDIRECT=$(cat "$SSL_REDIRECT_FILE" 2> /dev/null || echo $SSL_REDIRECT)
LANG=$(cat "$LANG_FILE" 2> /dev/null || echo $LANG)
BASE_URL=$(cat "$BASE_URL_FILE" 2> /dev/null || echo $BASE_URL)
DB_TYPE=$(cat "$DB_TYPE_FILE" 2> /dev/null || echo $DB_TYPE)
DB_HOST=$(cat "$DB_HOST_FILE" 2> /dev/null || echo $DB_HOST)
DB_PORT=$(cat "$DB_PORT_FILE" 2> /dev/null || echo $DB_PORT)
DB_USER=$(cat "$DB_USER_FILE" 2> /dev/null || echo $DB_USER)
MYSQL_USER=$(cat "$MYSQL_USER_FILE" 2> /dev/null || echo $MYSQL_USER)
DB_PASS=$(cat "$DB_PASS_FILE" 2> /dev/null || echo $DB_PASS)
MYSQL_PASSWORD=$(cat "$MYSQL_PASSWORD_FILE" 2> /dev/null || echo $MYSQL_PASSWORD)
DB_NAME=$(cat "$DB_NAME_FILE" 2> /dev/null || echo $DB_NAME)
MYSQL_DATABASE=$(cat "$MYSQL_DATABASE_FILE" 2> /dev/null || echo $MYSQL_DATABASE)
DB_PREFIX=$(cat "$DB_PREFIX_FILE" 2> /dev/null || echo $DB_PREFIX)
WT_USER=$(cat "$WT_USER_FILE" 2> /dev/null || echo $WT_USER)
WT_NAME=$(cat "$WT_NAME_FILE" 2> /dev/null || echo $WT_NAME)
WT_PASS=$(cat "$WT_PASS_FILE" 2> /dev/null || echo $WT_PASS)
WT_EMAIL=$(cat "$WT_EMAIL_FILE" 2> /dev/null || echo $WT_EMAIL)

auto_wizard () {
    # automatically try to complete the setup wizard
    echo "$PREFIX Attempting to automate setup wizard"

    # defaults
    lang="${LANG:-en-US}"
    dbtype="${DB_TYPE:-mysql}"
    dbport="${DB_PORT:-3306}"
    dbuser="${DB_USER:-${MYSQL_USER:-webtrees}}"
    dbname="${DB_NAME:-${MYSQL_DATABASE:-webtrees}}"
    tblpfx="${DB_PREFIX:-wt_}"

    # required
    dbhost="${DB_HOST}"
    dbpass="${DB_PASS:-$MYSQL_PASSWORD}"
    baseurl="${BASE_URL}"
    wtname="${WT_NAME}"
    wtuser="${WT_USER}"
    wtpass="${WT_PASS}"
    wtemail="${WT_EMAIL}"

    # test if config file exists
    if [ -f "$CONFIG_FILE" ]
    then
        echo "$PREFIX Config file found"

        # make sure all of the variables for the config file are present
        if [[ -z "$dbhost" || -z "$dbport" || -z "$dbuser" || -z "$dbpass" || -z "$dbname" || -z "$baseurl" ]]
        then
            echo "$PREFIX Not all variables required for config file update"
            return 0
        fi

        echo "$PREFIX Updating config file"

        # remove the line with sed, then write new content
        sed -i '/^dbhost/d' "$CONFIG_FILE" && echo "dbhost=\"$dbhost\"" >> $CONFIG_FILE
        sed -i '/^dbport/d' "$CONFIG_FILE" && echo "dbport=\"$dbport\"" >> $CONFIG_FILE
        sed -i '/^dbuser/d' "$CONFIG_FILE" && echo "dbuser=\"$dbuser\"" >> $CONFIG_FILE
        sed -i '/^dbpass/d' "$CONFIG_FILE" && echo "dbpass=\"$dbpass\"" >> $CONFIG_FILE
        sed -i '/^dbname/d' "$CONFIG_FILE" && echo "dbname=\"$dbname\"" >> $CONFIG_FILE
        sed -i '/^tblpfx/d' "$CONFIG_FILE" && echo "tblpfx=\"$tblpfx\"" >> $CONFIG_FILE
        sed -i '/^base_url/d' "$CONFIG_FILE" && echo "base_url=\"$baseurl\"" >> $CONFIG_FILE

    else
        echo "$PREFIX Config file NOT found"

        # make sure all of the variables needed for the setup wizard are present
        if [[ -z "$lang" || -z "$dbtype" || -z "$dbhost" || -z "$dbport" || -z "$dbuser" || -z "$dbpass" || -z "$dbname" || -z "$baseurl" || -z "$wtname" || -z "$wtuser" || -z "$wtpass" || -z "$wtemail" ]]
        then
            echo "$PREFIX Not all variables required for setup wizard present"
            return 0
        fi

        echo "$PREFIX Automating setup wizard"

        # start apache in the background quickly to send the request
        service apache2 start

        # set us up to a known HTTP state
        a2dissite webtrees-ssl
        a2dissite webtrees-redir
        a2ensite  webtrees
        service apache2 reload

        # wait until database is ready
        if [ "$dbtype" = "mysql" ]; then
            while ! mysqladmin ping -h"$dbhost" --silent; do
                echo "$PREFIX Waiting for MySQL server to be ready."
                sleep 1
            done
        else
            echo "$PREFIX Waiting 10 seconds arbitrarily for database server to be ready"
            sleep 10
        fi

        # POST the data and follow redirects and ignore SSL errors, if HTTPS is enabled and forced
        curl -L -k -X POST \
        -F "lang=$lang" \
        -F "dbtype=$dbtype" \
        -F "dbhost=$dbhost" \
        -F "dbport=$dbport" \
        -F "dbuser=$dbuser" \
        -F "dbpass=$dbpass" \
        -F "dbname=$dbname" \
        -F "tblpfx=$tblpfx" \
        -F "baseurl=$baseurl" \
        -F "wtname=$wtname" \
        -F "wtuser=$wtuser" \
        -F "wtpass=$wtpass" \
        -F "wtemail=$wtemail" \
        -F "step=6" \
        http://127.0.0.1:80

        # stop apache so that we can start it as a foreground process
        service apache2 stop
    fi
}

pretty_urls () {
    echo "$PREFIX Attempting to set pretty URLs status"

    if [ -f "$CONFIG_FILE" ]
    then
        echo "$PREFIX Config file found"

        # remove exisiting line from file
        sed -i '/^rewrite_urls/d' "$CONFIG_FILE"

        if [[ -z "${PRETTY_URLS}" ]]
        then
            echo "$PREFIX Removing pretty URLs"
            echo 'rewrite_urls="0"' >> $CONFIG_FILE
        else
            echo "$PREFIX Adding pretty URLs"
            echo 'rewrite_urls="1"' >> $CONFIG_FILE
        fi
    else
        echo "$PREFIX Config file NOT found, please setup webtrees"
    fi
}

https () {
    echo "$PREFIX Attempting to set HTTPS status"

    if [[ -z "${HTTPS}" && -z "${SSL}" ]]
    then
        echo "$PREFIX Removing HTTPS support"
        a2dissite webtrees-ssl
        a2dissite webtrees-redir
        a2ensite  webtrees
    else
        if [[ -z "${HTTPS_REDIRECT}" && -z "${SSL_REDIRECT}" ]]
        then
            echo "$PREFIX Adding HTTPS, removing HTTPS redirect"
            a2dissite webtrees-redir
            a2ensite  webtrees
            a2ensite  webtrees-ssl
        else
            echo "$PREFIX Adding HTTPS, adding HTTPS redirect"
            a2dissite webtrees
            a2ensite  webtrees-redir
            a2ensite  webtrees-ssl
        fi
    fi
}

auto_wizard
pretty_urls
https

echo "$PREFIX Starting Apache"

exec apache2-foreground

#Create persistence
if [ ! -f /data/config.ini.php ]; then
mv /var/www/webtrees/data/config.ini.php /data
ln -s /data/config.ini.php /var/www/webtrees/data
fi

if [ ! -f /data/webtrees.sqlite ]; then
    sleep 5m
    until [ -f /var/www/webtrees/data/webtrees.sqlite ]
    do
         sleep 5m
    done
        mv /var/www/webtrees/data/webtrees.sqlite /data
        ln -s /data/webtrees.sqlite /var/www/webtrees/data
    exit
fi
