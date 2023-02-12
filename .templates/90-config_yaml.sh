#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2155,SC1087,SC2163,SC2116,SC2086

##################
# INITIALIZATION #
##################

# Where is the config
CONFIGSOURCE=$(bashio::config "CONFIG_LOCATION")
# Check CONFIGSOURCE ends with config.yaml
if [ "$(basename "$CONFIGSOURCE")" != "config.yaml" ]; then
    bashio::log.error "Watchout: your CONFIG_LOCATION should end by config.yaml, and instead it is $(basename "$CONFIGSOURCE")"
fi

# Check if config is located in an acceptable location
LOCATIONOK=""
for location in "/share" "/config" "/data"; do
    if [[ "$CONFIGSOURCE" == "$location"* ]]; then
        LOCATIONOK=true
    fi
done

if [ -z "$LOCATIONOK" ]; then
    CONFIGSOURCE=/config/addons_config/${HOSTNAME#*-}
    bashio::log.fatal "Your CONFIG_LOCATION values can only be set in /share, /config or /data (internal to addon). It will be reset to the default location : $CONFIGSOURCE"
fi

# Check if config file is there, or create one from template
if [ -f "$CONFIGSOURCE" ]; then
    echo "Using config file found in $CONFIGSOURCE"
else
    echo "No config file, creating one from template"
    # Create folder
    mkdir -p "$(dirname "${CONFIGSOURCE}")"
    # Placing template in config
    if [ -f /templates/config.yaml ]; then
        # Use available template
        cp /templates/config.yaml "$(dirname "${CONFIGSOURCE}")"
    else
        # Download template
        TEMPLATESOURCE="https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/config.template"
        curl -f -L -s -S "$TEMPLATESOURCE" --output "$CONFIGSOURCE"
    fi
    # Need to restart
    bashio::log.fatal "Config file not found, creating a new one. Please customize the file in $CONFIGSOURCE before restarting."
    bashio::addon.stop
fi

# Permissions
chmod -R 755 "$(dirname "${CONFIGSOURCE}")"

# Check if yaml is valid
EXIT_CODE=0
yamllint -d relaxed "$CONFIGSOURCE" &>ERROR || EXIT_CODE=$?
if [ "$EXIT_CODE" = 0 ]; then
    echo "Config file is a valid yaml"
else
    cat ERROR
    bashio::log.warning "Config file has an invalid yaml format. Please check the file in $CONFIGSOURCE. Errors list above."
    # bashio::exit.nok
fi

# Check if = instead of :
if [[ "$(grep -c "=" "$CONFIGSOURCE")" -gt 2 ]]; then
    bashio::log.warning 'Are you sure you did not use "KEY=VALUE" ? yaml nomenclature requires "KEY:VALUE"'
fi

# Export all yaml entries as env variables
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

# Get variables and export
bashio::log.info "Starting the app with the variables in $CONFIGSOURCE"
# Get list of parameters in a file
parse_yaml "$CONFIGSOURCE" "" >/tmpfile
# Escape dollars
sed -i 's|$.|\$|g' /tmpfile

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
        # Export to scripts
        sed -i "1a export $line" /etc/services.d/*/*run* 2>/dev/null || true
        sed -i "1a export $line" /etc/cont-init.d/*run* 2>/dev/null || true
        sed -i "1a export $line" /scripts/*run* 2>/dev/null || true
        # Export to s6
        if [ -d /var/run/s6/container_environment ]; then printf "${VALUE}" > /var/run/s6/container_environment/"${KEYS}"; fi
        # export to python
        if command -v "python3" &>/dev/null; then
            [ ! -f /env.py ] && echo "import os" > /env.py
            echo "os.environ['${line%%=*}'] = '${line#*=}'" >> /env.py
            python3 /env.py
        fi
        # set .env
        echo "$line" >> /.env || true
        mkdir -p /etc
        echo "$line" >> /etc/environmemt
        # Show in log
        if ! bashio::config.false "verbose"; then bashio::log.blue "$line"; fi
    else
        bashio::exit.nok "$line does not follow the correct structure. Please check your yaml file."
    fi
done <"/tmpfile"

# Test mode
TZ=$(bashio::config "TZ")
if [ "$TZ" = "test" ]; then
    echo "secret mode found, launching script in /config/test.sh"
    cd /config || exit
    chmod 777 test.sh
    ./test.sh
fi
