#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2086
set -e

# Runs only after initialization done
# shellcheck disable=SC2128
if [ ! -f /app/www/public/occ ]; then cp /etc/cont-init.d/"$(basename "${BASH_SOURCE}")" /scripts/ && exit 0; fi

# Only execute if installed
if [ -f /notinstalled ]; then exit 0; fi

# Specify launcher
PUID=$(bashio::config "PUID")
PGID=$(bashio::config "PGID")
LAUNCHER="sudo -u abc php /app/www/public/occ"

if $LAUNCHER fulltextsearch:test &> /dev/null; then
    echo "Full Text Search is already working"

    ############
    # BASED ON #
    #################################################################################
    # https://raw.githubusercontent.com/nextcloud/vm/master/apps/fulltextsearch.sh  #
    # T&M Hansson IT AB © - 2021, https://www.hanssonit.se/                         #
    # SwITNet Ltd © - 2021, https://switnet.net/                                    #
    #################################################################################

    if bashio::config.true 'Full_Text_Search'; then

        # Get Full Text Search app for nextcloud
        echo "Installing Full Text Search"
        for app in "${APPS[@]}"; do
            echo "... installing apps : $app"
            $LAUNCHER app:install $app > /dev/null
            $LAUNCHER app:enable $app > /dev/null
    done
        chown -R "$PUID":"$PGID" $NEXTCLOUD_PATH/apps

        if bashio::config.has_value 'elasticsearch_server'; then
            HOST=$(bashio::config 'elasticsearch_server')
    else
            bashio::log.warning 'Please define elasticsearch server url in addon options. Default value of http://db21ed7f-elasticsearch:9200 will be used'
            HOST=http://db21ed7f-elasticsearch:9200
    fi

        # Final setup
        echo "... settings apps"
        $LAUNCHER fulltextsearch_elasticsearch:configure "{\"elastic_host\":\"$HOST\"}" &> /dev/null
        $LAUNCHER fulltextsearch_elasticsearch:configure '{"elastic_index":"my_index"}'     &> /dev/null
        $LAUNCHER fulltextsearch_elasticsearch:configure '{"analyzer_tokenizer":"standard"}'     &> /dev/null
        $LAUNCHER fulltextsearch:configure '{"search_platform":"OCA\\FullTextSearch_Elasticsearch\\Platform\\ElasticSearchPlatform"}' &> /dev/null || true
        $LAUNCHER files_fulltextsearch:configure '{"files_pdf":"1","files_office":"1"}'         &> /dev/null || true

        # Is server detected
        # Wait further for cache for index to work
        echo "Waiting for a few seconds before indexing starts..."
        sleep 5s
        if $LAUNCHER fulltextsearch:test &> /dev/null; then
            bashio::log.info "Full Text Search was successfully installed using elasticsearch server $HOST!"

    else

            bashio::log.warning "Elasticsearch can't connect. Please manually define its server in the options"
    fi
  else
        echo "Full_Text_Search option not set"
  fi
fi
