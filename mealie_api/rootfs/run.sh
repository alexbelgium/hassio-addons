#!/usr/bin/env bashio
# shellcheck shell=bash

####################
# Starting scripts #
####################

for SCRIPTS in /etc/cont-init.d/*; do
    [ -e "$SCRIPTS" ] || continue
    echo "$SCRIPTS: executing"
    chown "$(id -u)":"$(id -g)" "$SCRIPTS"
    chmod a+x "$SCRIPTS"
    # Change shebang if no s6 supervision
    sed -i 's|/usr/bin/with-contenv bashio|/usr/bin/env bashio|g' "$SCRIPTS"
    /."$SCRIPTS" || echo "$SCRIPTS: exiting $?"
done

####################
# Export variables #
####################

bashio::log.info "Exporting variables"
for k in $(bashio::jq "/data/options.json" 'keys | .[]'); do
    bashio::log.blue "$k"="$(bashio::config "$k")"
    export "$k"="$(bashio::config "$k")"
done

###############
# CONFIG YAML #
###############

CONFIGSOURCE="/config/addons_config/mealie/config.yaml"

if [ -f "$CONFIGSOURCE" ]; then
bashio::log.info "config.yaml found in $CONFIGSOURCE, exporting variables"

# Helper function
function parse_yaml {
    local prefix=$2 || local prefix=""
    local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @ | tr @ '\034')
    sed -ne "s|^\($s\):|\1|" \
        -e "s| #.*$||g" \
        -e "s|#.*$||g" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" $1 |
    awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
    }'
}

# Get list of parameters in a file
parse_yaml "$CONFIGSOURCE" "" >/tmpfile
while IFS= read -r line; do
    # Clean output
    line="${line//[\"\']/}"
    # Check if secret
    if [[ "${line}" == *'!secret '* ]]; then
        echo "secret detected"
        secret=${line#*secret }
        # Check if single match
        secretnum=$(sed -n "/$secret:/=" /config/secrets.yaml)
        [[ $(echo $secretnum) == *' '* ]] && bashio::exit.nok "There are multiple matches for your password name. Please check your secrets.yaml file"
        # Get text
        secret=$(sed -n "/$secret:/p" /config/secrets.yaml)
        secret=${secret#*: }
        line="${line%%=*}='$secret'"
    fi
    # Data validation
    if [[ "$line" =~ ^.+[=].+$ ]]; then
        export "$line"
        # Show in log
        if ! bashio::config.false "verbose"; then bashio::log.blue "$line"; fi
    else
        bashio::exit.nok "$line does not follow the correct structure. Please check your yaml file."
    fi
done <"/tmpfile"

else
bashio::log.info "No config.yaml found in $CONFIGSOURCE, using default parameters"
fi

###############
# PERMISSIONS #
###############

echo "Permissions adapted"
chmod -R 777 /data

#######
# SSL #
#######

bashio::config.require.ssl
if bashio::config.true 'ssl'; then
   bashio::log.info "Configuring ssl"
   CERTFILE=$(bashio::config 'certfile')
   KEYFILE=$(bashio::config 'keyfile')
   if [ -f /app/Caddyfile ]; then sed -i "7 i tls /ssl/$CERTFILE /ssl/$KEYFILE" /app/Caddyfile; fi
   if [ -f /app/frontend/Caddyfile ]; then sed -i "7 i tls /ssl/$CERTFILE /ssl/$KEYFILE" /app/frontend/Caddyfile; fi
fi 
