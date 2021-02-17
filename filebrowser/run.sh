#!/usr/bin/cont-env bashio

####################
# MOUNT SMB SHARES #
####################
# Mount CIFS Share if configured and if Protection Mode is active
if bashio::config.has_value 'networkdisks'; then
    bashio::log.info 'Mounting smb share...'
    MOREDISKS=$(bashio::config 'networkdisks')
    CIFS_USERNAME=$(bashio::config 'cifsusername')
    CIFS_PASSWORD=$(bashio::config 'cifspassword')
    bashio::log.info "Network Disks mounting.. ${MOREDISKS}" && \
    for disk in $MOREDISKS 
    do
        bashio::log.info "Mount ${disk}"
        echo "Creating /storage/storagecifs"
        mkdir -p /storage/storagecifs
        chown -R abc:abc /storage/storagecifs
        mount -t cifs -o username=$CIFS_USERNAME,password=$CIFS_PASSWORD $disk /storage/storagecifs && \
        bashio::log.info "Success!"   
    done || \
    bashio::log.warning "Protection mode is ON. Unable to mount external drives!"
fi

######################
# LAUNCH FILEBROWSER #
######################
bashio::log.info "Default username/password : admin/admin"

./filebrowser --root=/ --address=0.0.0.0 --database=/config/filebrowser/filebrowser.db
