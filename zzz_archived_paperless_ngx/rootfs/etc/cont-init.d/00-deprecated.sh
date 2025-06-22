#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# ==============================================================================
# Displays a simple add-on banner on startup
# ==============================================================================

echo ""
bashio::log.yellow "####################"
bashio::log.yellow "# ADDON deprecated #"
bashio::log.yellow "####################"
echo ""
bashio::log.yellow "A better alternative is existing for paperless NGX managed by BenoitAnastay : https://github.com/BenoitAnastay/home-assistant-addons-repository"
bashio::log.yellow "It is recommended to transfer to his version that will be more robust and include ingress"
bashio::log.yellow "Thanks for all users over the years !"
echo ""

echo "Migration (thanks @eikeja) : 
- Install the new addon
- Make a backup of the old Paperless directory. In my case '/addon_configs/db21ed7f_paperless_ng'
- View the folder structure of the new instance, assign files from the old instance to the folders of the new instance.

Start new Paperless - all data is there!

Folder assignment:
/addon_configs/db21ed7f_paperless_ng/data → /addon_configs/ca5234a0_paperless-ngx/data

/addon_configs/db21ed7f_paperless_ng/media → /share/paperless"

sleep 5
