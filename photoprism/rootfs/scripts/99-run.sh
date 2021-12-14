#!/usr/bin/env bashio

##############
# LAUNCH APP #
##############

# Configure app
export PHOTOPRISM_UPLOAD_NSFW=$(bashio::config 'UPLOAD_NSFW')
export PHOTOPRISM_STORAGE_PATH=$(bashio::config 'STORAGE_PATH')
export PHOTOPRISM_ORIGINALS_PATH=$(bashio::config 'ORIGINALS_PATH')
export PHOTOPRISM_IMPORT_PATH=$(bashio::config 'IMPORT_PATH')
export PHOTOPRISM_BACKUP_PATH=$(bashio::config 'BACKUP_PATH')

if bashio::config.has_value 'CUSTOM_OPTIONS'; then
  CUSTOMOPTIONS=$(bashio::config 'CUSTOM_OPTIONS')
else
  CUSTOMOPTIONS=""
fi

# Test configs
for variabletest in $PHOTOPRISM_STORAGE_PATH $PHOTOPRISM_ORIGINALS_PATH $PHOTOPRISM_IMPORT_PATH $PHOTOPRISM_BACKUP_PATH; do
  # Check if path exists
  if bashio::fs.directory_exists $variabletest; then
    true
  else
    bashio::log.info "Path $variabletest doesn't exist. Creating it now..."
    mkdir -p $variabletest || bashio::log.fatal "Can't create $variabletest path"
  fi
  # Check if path writable
  touch $variabletest/aze && rm $variabletest/aze || bashio::log.fatal "$variable path is not writable"
done

# Start messages
bashio::log.info "Please wait 1 or 2 minutes to allow the server to load"
bashio::log.info 'Default username : admin, default password: "please_change_password"'

cd /
./entrypoint_photoprism.sh photoprism start '"'$CUSTOMOPTIONS'"'
