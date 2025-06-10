#!/usr/bin/env bashio
# shellcheck shell=bash
# shellcheck disable=SC2155,SC2015
set -e

###########
# SCRIPTS #
###########

for SCRIPTS in "/00-banner.sh" "/00-local_mounts.sh" "/00-smb_mounts.sh"; do
    echo $SCRIPTS
    chown "$(id -u)":"$(id -g)" "$SCRIPTS"
    chmod a+x $SCRIPTS
    sed -i 's|/usr/bin/with-contenv bashio|/usr/bin/env bashio|g' $SCRIPTS
    /.$SCRIPTS &&
    true || true # Prevents script crash on failure
    echo "exit $?"
done

##############
# LAUNCH APP #
##############

# Configure app
export PHOTOPRISM_UPLOAD_NSFW=$(bashio::config 'UPLOAD_NSFW')
export PHOTOPRISM_STORAGE_PATH=$(bashio::config 'STORAGE_PATH')
export PHOTOPRISM_ORIGINALS_PATH=$(bashio::config 'ORIGINALS_PATH')
export PHOTOPRISM_IMPORT_PATH=$(bashio::config 'IMPORT_PATH')
export PHOTOPRISM_BACKUP_PATH=$(bashio::config 'BACKUP_PATH')

{
    printf "%s\n" "PHOTOPRISM_UPLOAD_NSFW=\"${PHOTOPRISM_UPLOAD_NSFW}\""
    printf "%s\n" "PHOTOPRISM_STORAGE_PATH=\"${PHOTOPRISM_STORAGE_PATH}\""
    printf "%s\n" "PHOTOPRISM_ORIGINALS_PATH=\"${PHOTOPRISM_ORIGINALS_PATH}\""
    printf "%s\n" "PHOTOPRISM_IMPORT_PATH=\"${PHOTOPRISM_IMPORT_PATH}\""
    printf "%s\n" "PHOTOPRISM_BACKUP_PATH=\"${PHOTOPRISM_BACKUP_PATH}\""
} >>~/.bashrc

if bashio::config.has_value 'CUSTOM_OPTIONS'; then
    CUSTOMOPTIONS=$(bashio::config 'CUSTOM_OPTIONS')
else
    CUSTOMOPTIONS=""
fi

# Test configs
for variabletest in $PHOTOPRISM_STORAGE_PATH $PHOTOPRISM_ORIGINALS_PATH $PHOTOPRISM_IMPORT_PATH $PHOTOPRISM_BACKUP_PATH; do
    # Check if path exists
    if bashio::fs.directory_exists "$variabletest"; then
        true
  else
        bashio::log.info "Path $variabletest doesn't exist. Creating it now..."
        mkdir -p "$variabletest" || bashio::log.fatal "Can't create $variabletest path"
  fi
    # Check if path writable
    # shellcheck disable=SC2015
    touch "$variabletest"/aze && rm "$variabletest"/aze || bashio::log.fatal "$variabletest path is not writable"
done

# Start messages
bashio::log.info "Please wait 1 or 2 minutes to allow the server to load"
bashio::log.info 'Default username : admin, default password: "please_change_password"'

cd /
./entrypoint.sh photoprism start '"'"$CUSTOMOPTIONS"'"'
