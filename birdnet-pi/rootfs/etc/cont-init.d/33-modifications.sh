#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

################
# MODIFY WEBUI #
################

echo " "
bashio::log.info "Adapting webui"

# Remove services tab
echo "... removing System Controls from webui as should be used from HA"
sed -i '/>System Controls/d' "$HOME"/BirdNET-Pi/homepage/views.php

# Remove services tab
echo "... removing Ram drive from webui as it is handled from HA"
sed -i '/Ram drive/{n;s/center"/center" style="display: none;"/;}' "$HOME"/BirdNET-Pi/scripts/service_controls.php
sed -i '/Ram drive/d' "$HOME"/BirdNET-Pi/scripts/service_controls.php

# Correct the phpsysinfo for the correct gotty service
gottyservice="$(pgrep -l "gotty" | awk '{print $NF}' | head -n 1)"
echo "... using $gottyservice in phpsysinfo"
sed -i "s/,gotty,/,${gottyservice:-gotty},/g" "$HOME"/BirdNET-Pi/templates/phpsysinfo.ini

# Set the online birds info system
if [[ "$(bashio::config "BIRDS_ONLINE_INFO")" == *"ebird"* ]]; then
    echo "... using ebird instead of allaboutbirds"
    mv /ebird.txt /home/pi/BirdNET-Pi/model/ebird.txt
    chown pi:pi /home/pi/BirdNET-Pi/model/ebird.txt
    # shellcheck disable=SC2016
    sed -i '/$sciname =/a \\t$ebirdname = shell_exec("grep \\"$( echo \\"$sciname\\" | sed '\''s/_/ /g'\'')\\" /home/pi/BirdNET-Pi/model/ebird.txt | cut -d'\''_'\'' -f2 | sed '\''s/ /_/g'\''");' "$HOME"/BirdNET-Pi/scripts/todays_detections.php
    # shellcheck disable=SC2016
    sed -i '/$sciname =/a \\t$ebirdname = shell_exec("grep \\"$( echo \\"$sciname\\" | sed '\''s/_/ /g'\'')\\" /home/pi/BirdNET-Pi/model/ebird.txt | cut -d'\''_'\'' -f2 | sed '\''s/ /_/g'\''");' "$HOME"/BirdNET-Pi/scripts/stats.php
    sed -i "s|https://allaboutbirds.org/guide/<?php echo \$comname;?>|https://ebird.org/species/<?php echo \$ebirdname;?>?siteLanguage=${DATABASE_LANG}_${DATABASE_LANG}|g" "$HOME"/BirdNET-Pi/scripts/todays_detections.php
    sed -i "s|https://allaboutbirds.org/guide/\$comname|https://ebird.org/species/\$ebirdname?siteLanguage=${DATABASE_LANG}_${DATABASE_LANG}|g" "$HOME"/BirdNET-Pi/scripts/stats.php
else
    # Correct allaboutbirds for non-english names
    echo "... using allaboutbirds, with correction for non-english names"
    # shellcheck disable=SC2016
    sed -i '/$sciname =/a \\t$comnameen = shell_exec("grep \\"$( echo \\"$sciname\\" | sed '\''s/_/ /g'\'')\\" /home/pi/BirdNET-Pi/model/labels.bak | cut -d'\''_'\'' -f2 | sed '\''s/ /_/g'\''");' "$HOME"/BirdNET-Pi/scripts/todays_detections.php
    # shellcheck disable=SC2016
    sed -i '/$sciname =/a \\t$comnameen = shell_exec("grep \\"$( echo \\"$sciname\\" | sed '\''s/_/ /g'\'')\\" /home/pi/BirdNET-Pi/model/labels.bak | cut -d'\''_'\'' -f2 | sed '\''s/ /_/g'\''");' "$HOME"/BirdNET-Pi/scripts/stats.php
    # shellcheck disable=SC2016
    sed -i 's|allaboutbirds.org/guide/<?php echo $comname|allaboutbirds.org/guide/<?php echo $comnameen|g' "$HOME"/BirdNET-Pi/scripts/todays_detections.php
    sed -i "s|https://allaboutbirds.org/guide/\$comname|https://allaboutbirds.org/guide/\$comnameen|g" "$HOME"/BirdNET-Pi/scripts/stats.php
fi
