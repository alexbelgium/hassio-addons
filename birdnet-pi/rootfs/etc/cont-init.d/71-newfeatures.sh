#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

################
# ADD FEATURES #
################

echo " "
bashio::log.info "Adding new features"

# Set the online birds info system
##################################
if [[ "$(bashio::config "BIRDS_ONLINE_INFO")" == *"ebird"* ]]; then
    echo "... using ebird instead of allaboutbirds"
    # Set ebird database
    mv /helpers/ebird.txt /home/pi/BirdNET-Pi/model/ebird.txt
    chown pi:pi /home/pi/BirdNET-Pi/model/ebird.txt
    # Get language
    export "$(grep "^DATABASE_LANG" /config/birdnet.conf)"
    # shellcheck disable=SC2016
    sed -i '/$sciname =/a \\t$ebirdname = shell_exec("grep \\"$( echo \\"$sciname\\" | sed '\''s/_/ /g'\'')\\" /home/pi/BirdNET-Pi/model/ebird.txt | cut -d'\''_'\'' -f2 | sed '\''s/ /_/g'\''");' "$HOME"/BirdNET-Pi/scripts/todays_detections.php
    sed -i "s|https://allaboutbirds.org/guide/<?php echo \$comname;?>|https://ebird.org/species/<?php echo \$ebirdname;?>?siteLanguage=${DATABASE_LANG}_${DATABASE_LANG}|g" "$HOME"/BirdNET-Pi/scripts/todays_detections.php
    # shellcheck disable=SC2016
    sed -i '/$sciname =/a \\t$ebirdname = shell_exec("grep \\"$( echo \\"$sciname\\" | sed '\''s/_/ /g'\'')\\" /home/pi/BirdNET-Pi/model/ebird.txt | cut -d'\''_'\'' -f2 | sed '\''s/ /_/g'\''");' "$HOME"/BirdNET-Pi/scripts/stats.php
    sed -i "s|https://allaboutbirds.org/guide/\$comname|https://ebird.org/species/\$ebirdname?siteLanguage=${DATABASE_LANG}_${DATABASE_LANG}|g" "$HOME"/BirdNET-Pi/scripts/stats.php
else
    # Correct allaboutbirds for non-english names
    echo "... using allaboutbirds, with correction for non-english names"
    # shellcheck disable=SC2016
    sed -i 's|allaboutbirds.org/guide/<?php echo $comname|allaboutbirds.org/guide/<?php echo $comnameen|g' "$HOME"/BirdNET-Pi/scripts/todays_detections.php
    # shellcheck disable=SC2016
    sed -i '/$sciname =/a \\t$comnameen = shell_exec("grep \\"$( echo \\"$sciname\\" | sed '\''s/_/ /g'\'')\\" /home/pi/BirdNET-Pi/model/labels.bak | cut -d'\''_'\'' -f2 | sed '\''s/ /_/g'\''");' "$HOME"/BirdNET-Pi/scripts/todays_detections.php
    # shellcheck disable=SC2016
    sed -i '/$sciname =/a \\t$comnameen = shell_exec("grep \\"$( echo \\"$sciname\\" | sed '\''s/_/ /g'\'')\\" /home/pi/BirdNET-Pi/model/labels.bak | cut -d'\''_'\'' -f2 | sed '\''s/ /_/g'\''");' "$HOME"/BirdNET-Pi/scripts/stats.php
    # shellcheck disable=SC2016
    sed -i "s|https://allaboutbirds.org/guide/\$comname|https://allaboutbirds.org/guide/\$comnameen|g" "$HOME"/BirdNET-Pi/scripts/stats.php
fi

# Convert Adminer to iframe
###############################
if ! grep "iframe src=\'scripts/adminer.php" "$HOME"/BirdNET-Pi/homepage/views.php; then
    sed -i '/scripts\/adminer.php\\/c\      <button type=\\"submit\\" name=\\"view\\" value=\\"Adminer\\" form=\\"views\\">Database Maintenance</button>' "$HOME"/BirdNET-Pi/homepage/views.php
    sed -i "/advanced.php/a\  if(\$_GET\['view'\] == \"Adminer\"){echo \"<iframe src='scripts/adminer.php'></iframe>\";}" "$HOME"/BirdNET-Pi/homepage/views.php
    sed -i "s|deny|SameOrigin|g" "$HOME"/BirdNET-Pi/scripts/adminer.php
    sed -i "1a echo '<a href=\"'.\$_SERVER\['PHP_SELF'\]\.'\" target=\"_blank\">Open in new page</a>';" "$HOME"/BirdNET-Pi/scripts/adminer.php
fi

# Add weekly report button
###############################
if ! grep -q "Weekly Report" "$HOME"/BirdNET-Pi/homepage/views.php; then
    sed -i "67a\  <button type=\"submit\" name=\"view\" value=\"Weekly Report\" form=\"views\">Weekly Report</button>" "$HOME"/BirdNET-Pi/homepage/views.php
fi

# Add species conversion system
###############################

if ! grep -q "Converted" "$HOME"/BirdNET-Pi/homepage/views.php; then
    echo "... adding feature of SPECIES_CONVERTER, a new tab is added to your Tools"
    touch /config/convert_species_list.txt
    chown pi:pi /config/convert_species_list.txt
    sudo -u pi ln -fs /config/convert_species_list.txt "$HOME"/BirdNET-Pi/
    sudo -u pi ln -fs /config/convert_species_list.txt "$HOME"/BirdNET-Pi/scripts/
    # Not useful
    sed -i "/exclude_species_list.txt/a sudo -u pi ln -fs /config/convert_species_list.txt $HOME/BirdNET-Pi/scripts/" "$HOME"/BirdNET-Pi/scripts/clear_all_data.sh
    sed -i "/exclude_species_list.txt/a sudo -u pi ln -fs /config/convert_species_list.txt $HOME/BirdNET-Pi/scripts/" "$HOME"/BirdNET-Pi/scripts/install_services.sh
    # Modify views.php if not already done
    if ! grep -q "Converted" "$HOME"/BirdNET-Pi/homepage/views.php; then
        # Add button
        # shellcheck disable=SC2016
        sed -i '/Excluded Species List/a\      <button type=\\"submit\\" name=\\"view\\" value=\\"Converted\\" form=\\"views\\">Converted Species List</button>' "$HOME"/BirdNET-Pi/homepage/views.php
        # Flag to indicate whether we've found the target line
        found_target=false
        # Read the original file line by line
        while IFS= read -r line; do
            if [[ $line == *"if(\$_GET['view'] == \"File\"){"* ]]; then
                found_target=true
            fi
            if $found_target; then
                echo "$line" >> "$HOME"/BirdNET-Pi/homepage/views.php.temp
            fi
        done < "$HOME"/BirdNET-Pi/homepage/views.php
        # Remove the extracted lines from the original file
        # shellcheck disable=SC2016
        sed -i '/if(\$_GET\['\''view'\''\] == "File"){/,$d' "$HOME"/BirdNET-Pi/homepage/views.php
        # Add new text
        cat "/helpers/views.add" >> "$HOME"/BirdNET-Pi/homepage/views.php
        cat "$HOME"/BirdNET-Pi/homepage/views.php.temp >> "$HOME"/BirdNET-Pi/homepage/views.php
        # Clean up: Remove the temporary file
        rm "$HOME"/BirdNET-Pi/homepage/views.php.temp
    fi

    # Add the converter script
    if [ ! -f "$HOME"/BirdNET-Pi/scripts/convert_list.php ]; then
        mv -f /helpers/convert_list.php "$HOME"/BirdNET-Pi/scripts/convert_list.php
        chown pi:pi "$HOME"/BirdNET-Pi/scripts/convert_list.php
        chmod 664 "$HOME"/BirdNET-Pi/scripts/convert_list.php
    fi

    # Change server
    if ! grep -q "converted_entry" "$HOME"/BirdNET-Pi/scripts/server.py; then
        sed -i "/INTERPRETER, M_INTERPRETER, INCLUDE_LIST, EXCLUDE_LIST/c INTERPRETER, M_INTERPRETER, INCLUDE_LIST, EXCLUDE_LIST, CONVERT_LIST = (None, None, None, None, None)" "$HOME"/BirdNET-Pi/scripts/server.py
        sed -i "/global INCLUDE_LIST, EXCLUDE_LIST/c\    global INCLUDE_LIST, EXCLUDE_LIST, CONVERT_LIST, CONVERT_DICT" "$HOME"/BirdNET-Pi/scripts/server.py
        sed -i "/exclude_species_list.txt/a\    CONVERT_DICT = {row.split(';')[0]: row.split(';')[1] for row in CONVERT_LIST}" "$HOME"/BirdNET-Pi/scripts/server.py
        sed -i "/exclude_species_list.txt/a\    CONVERT_LIST = loadCustomSpeciesList(os.path.expanduser(\"~/BirdNET-Pi/convert_species_list.txt\"))" "$HOME"/BirdNET-Pi/scripts/server.py
        sed -i "s|entry\[0\]|converted_entry|g" "$HOME"/BirdNET-Pi/scripts/server.py
        sed -i "s|if converted_entry in|if entry\[0\] in|g" "$HOME"/BirdNET-Pi/scripts/server.py
        sed -i "/for entry in entries/a\                    converted_entry = entry[0]" "$HOME"/BirdNET-Pi/scripts/server.py
        sed -i "/for entry in entries/a\                else :" "$HOME"/BirdNET-Pi/scripts/server.py
        sed -i "/for entry in entries/a\                    log.info('WARNING : ' + entry[0] + ' converted to ' + converted_entry)" "$HOME"/BirdNET-Pi/scripts/server.py
        sed -i "/for entry in entries/a\                    converted_entry = CONVERT_DICT.get(entry[0], entry[0])" "$HOME"/BirdNET-Pi/scripts/server.py
        sed -i "/for entry in entries/a\                if entry[0] in CONVERT_DICT:" "$HOME"/BirdNET-Pi/scripts/server.py
        sed -i "/for entry in entries/a\            if entry[1] >= conf.getfloat('CONFIDENCE'):" "$HOME"/BirdNET-Pi/scripts/server.py
        sed -i "/converted_entry in INCLUDE_LIST or len(INCLUDE_LIST)/c\                if ((converted_entry in INCLUDE_LIST or len(INCLUDE_LIST) == 0)" "$HOME"/BirdNET-Pi/scripts/server.py
        sed -i "s|                d = Detection|                    d = Detection|g" "$HOME"/BirdNET-Pi/scripts/server.py
        sed -i "s|                confident_detections|                    confident_detections|g" "$HOME"/BirdNET-Pi/scripts/server.py
    fi
fi

# Enable the Processed folder
echo "... Enabling the Processed folder : the last 15 wav files will be stored there"
"$PYTHON_VIRTUAL_ENV" /helpers/addition_processed.py

echo " "
