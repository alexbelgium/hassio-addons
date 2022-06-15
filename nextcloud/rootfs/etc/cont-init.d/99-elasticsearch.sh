#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2086

LAUNCHER="sudo -u abc php /data/config/www/nextcloud/occ" || bashio::log.info "/data/config/www/nextcloud/occ not found"
if ! bashio::fs.file_exists '/data/config/www/nextcloud/occ'; then
    LAUNCHER=$(find / -name "occ" -print -quit)
fi || bashio::log.info "occ not found"

# Make sure there is an Nextcloud installation
if [[ $($LAUNCHER -V) == *"not installed"* ]]; then
    bashio::log.warning "It seems there is no Nextcloud server installed. Please restart the addon after initialization of the user."
    exit 0
fi

############
# BASED ON #
#################################################################################
# https://raw.githubusercontent.com/nextcloud/vm/master/apps/fulltextsearch.sh  #
# T&M Hansson IT AB © - 2021, https://www.hanssonit.se/                         #
# SwITNet Ltd © - 2021, https://switnet.net/                                    #
#################################################################################

if bashio::config.true 'Full_Text_Search'; then
    # shellcheck disable=SC1073,SC1072,SC1009
    if [ $LAUNCHER fulltextsearch:index &>/dev/null ]; then
        echo "Full Text Search is already working"
        break 2
    fi

    echo "Installing Full Text Search"
    # Reset Full Text Search to be able to index again, and also remove the app to be able to install it again
    occ fulltextsearch:reset &>/dev/null || true
    APPS=(fulltextsearch fulltextsearch_elasticsearch files_fulltextsearch)
    for app in "${APPS[@]}"; do
        # If app exists, remove it
        [ -n $($LAUNCHER app:getpath $app) ] && $LAUNCHER app:remove $app &>/dev/null
    done

    # Get Full Text Search app for nextcloud
    for app in "${APPS[@]}"; do
        echo "... installing apps : $app"
        $LAUNCHER app:install $app >/dev/null
        $LAUNCHER app:enable $app >/dev/null
    done
    chown -R abc:abc $NEXTCLOUD_PATH/apps

    if bashio::config.has_value 'elasticsearch_server'; then
        HOST=$(bashio::config 'elasticsearch_server')
    else
        bashio::log.warning 'Please define elasticsearch server url in addon options with the format "ip:port" such as "192.168.178.1:9200"'
        HOST=$(bashio::network.ipv4_address)
        HOST="${HOST%/*}:9200"
    fi

    # Final setup
    echo "... settings apps"
    #occ fulltextsearch:configure '{"search_platform":"ElasticSearchPlatform"}'
    $LAUNCHER fulltextsearch_elasticsearch:configure "{\"elastic_host\":\"http://$HOST:9200\"}" &>/dev/null
    $LAUNCHER fulltextsearch_elasticsearch:configure "{\"elastic_index\":\"my_index\"}" &>/dev/null
    $LAUNCHER fulltextsearch_elasticsearch:configure "{\"analyzer_tokenizer\":\"standard\"}" &>/dev/null
    $LAUNCHER fulltextsearch:configure '{"search_platform":"OCA\\FullTextSearch_Elasticsearch\\Platform\\ElasticSearchPlatform"}' &>/dev/null || true
    $LAUNCHER files_fulltextsearch:configure "{\"files_pdf\":\"1\",\"files_office\":\"1\"}" &>/dev/null || true

    # Is server detected
    # if [ curl $HOST ] &>/dev/null; then
    # Wait further for cache for index to work
    echo "Waiting for a few seconds before indexing starts..."
    sleep 10s
    if $LAUNCHER fulltextsearch:index &>/dev/null; then
        bashio::log.info "Full Text Search was successfully installed using elasticsearch server $HOST!"

    else

        bashio::log.warning "Elasticsearch can't connect. Please manually define its server in the options"
    fi
else
    echo "Full_Text_Search option not set"
fi
