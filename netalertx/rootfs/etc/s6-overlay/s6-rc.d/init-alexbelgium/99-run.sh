#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

bashio::log.warning "App starting."



# In the addon script, make symlinks on the fly
echo "Creating symlinks"
for folder in config db; do
    echo "Creating for $folder"
    # Create symlinks
    mkdir -p /config/"$folder"
    if [ -d /app/"$folder" ] && [ "$(ls -A /app/"$folder")" ]; then
        cp -rn /app/"$folder"/* /config/"$folder"/
    fi
    rm -r /app/"$folder"
    ln -sf /config/"$folder" /app/"$folder"
done


chmod a+rwx /config/db/app.db
sudo chown -R nginx:www-data /config/db/
sudo chown -R nginx:www-data /config/config/

##############
# LAUNCH APP #
##############

chmod +x /app/dockerfiles/start.sh
/app/dockerfiles/start.sh
