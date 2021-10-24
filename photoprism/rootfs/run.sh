#!/usr/bin/env bashio

bashio::log.warning "Warning - minimum configuration recommended : 2 cpu cores and 4 GB of memory"

##########
# BANNER #
##########

if bashio::supervisor.ping; then
  bashio::log.blue \
    '-----------------------------------------------------------'
  bashio::log.blue " Add-on: $(bashio::addon.name)"
  bashio::log.blue " $(bashio::addon.description)"
  bashio::log.blue \
    '-----------------------------------------------------------'

  bashio::log.blue " Add-on version: $(bashio::addon.version)"
  if bashio::var.true "$(bashio::addon.update_available)"; then
    bashio::log.magenta ' There is an update available for this add-on!'
    bashio::log.magenta \
      " Latest add-on version: $(bashio::addon.version_latest)"
    bashio::log.magenta ' Please consider upgrading as soon as possible.'
  else
    bashio::log.green ' You are running the latest version of this add-on.'
  fi

  bashio::log.blue " System: $(bashio::info.operating_system)" \
    " ($(bashio::info.arch) / $(bashio::info.machine))"
  bashio::log.blue " Home Assistant Core: $(bashio::info.homeassistant)"
  bashio::log.blue " Home Assistant Supervisor: $(bashio::info.supervisor)"

  bashio::log.blue \
    '-----------------------------------------------------------'
  bashio::log.blue \
    ' Please, share the above information when looking for help'
  bashio::log.blue \
    ' or support in, e.g., GitHub, forums or the Discord chat.'
  bashio::log.green \
    ' https://github.com/alexbelgium/hassio-addons'
  bashio::log.blue \
    '-----------------------------------------------------------'
fi

######################
# MOUNT LOCAL SCRIPT #
######################
chown $(id -u):$(id -g) /92-local_mounts.sh
chmod a+x /92-local_mounts.sh
sed -i 's|/usr/bin/with-contenv bashio|/usr/bin/env bashio|g' /92-local_mounts.sh
/./92-local_mounts.sh &
true # Prevents script crash on failure

######################
# EXECUTE SMB SCRIPT #
######################
chown $(id -u):$(id -g) /92-smb_mounts.sh
chmod a+x /92-smb_mounts.sh
sed -i 's|/usr/bin/with-contenv bashio|/usr/bin/env bashio|g' /92-smb_mounts.sh
/./92-smb_mounts.sh &
true # Prevents script crash on failure

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
./entrypoint.sh photoprism start '"'$CUSTOMOPTIONS'"'
