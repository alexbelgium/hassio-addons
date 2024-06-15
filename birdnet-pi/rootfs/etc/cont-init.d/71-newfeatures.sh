#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

################
# ADD FEATURES #
################

echo " "
bashio::log.info "Adding new features"

# Add analysis in 24 bits
if bashio::config.true "24BITS_ANALYSIS"; then
    echo "... using 24 bits instead of 64 bits for wav analysis. Use only if you feed a 24 bits stream. For info, the model is trained in 16bits"
    sed -i "s|s16le|s24le|g" "$HOME"/BirdNET-Pi/scripts/birdnet_recording.sh
    sed -i "s|S16_LE|S24_LE|g" "$HOME"/BirdNET-Pi/scripts/birdnet_recording.sh
fi

# Add species conversion system
###############################
if bashio::config.true "SPECIES_CONVERTER_ENABLED"; then
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
fi || true

# Enable the Processed folder
#############################

if bashio::config.true "PROCESSED_FOLDER_ENABLED" && ! grep -q "processed_size" "$HOME"/BirdNET-Pi/scripts/birdnet_analysis.py; then
    echo "... Enabling the Processed folder : the last 15 wav files will be stored there"
    # Adapt config.php
    sed -i "/GET\[\"info_site\"\]/a\  \$processed_size = \$_GET\[\"processed_size\"\];" "$HOME"/BirdNET-Pi/scripts/config.php
    sed -i "/\$contents = file_get_contents/a\  \$contents = preg_replace\(\"/PROCESSED_SIZE=\.\*/\", \"PROCESSED_SIZE=\$processed_size\", \$contents\);" "$HOME"/BirdNET-Pi/scripts/config.php
    sed -i "/\"success\"/i      <table class=\"settingstable\"><tr><td>" "$HOME"/BirdNET-Pi/scripts/config.php
    sed -i "/\"success\"/i      <h2>Processed folder management </h2>" "$HOME"/BirdNET-Pi/scripts/config.php
    sed -i "/\"success\"/i      <label for=\"processed_size\">Amount of files to keep after analysis :</label>" "$HOME"/BirdNET-Pi/scripts/config.php
    sed -i "/\"success\"/i      <input name=\"processed_size\" type=\"number\" style=\"width:6em;\" max=\"90\" min=\"0\" step=\"1\" value=\"<\?php print(\$config\['PROCESSED_SIZE'\]);?>\"/>" "$HOME"/BirdNET-Pi/scripts/config.php
    sed -i "/\"success\"/i      </td></tr><tr><td>" "$HOME"/BirdNET-Pi/scripts/config.php
    sed -i "/\"success\"/i      Processed is the directory where the formerly 'Analyzed' files are moved after extractions, mostly for troubleshooting purposes.<br>" "$HOME"/BirdNET-Pi/scripts/config.php
    sed -i "/\"success\"/i      This value defines the maximum amount of files that are kept before replacement with new files.<br>" "$HOME"/BirdNET-Pi/scripts/config.php
    sed -i "/\"success\"/i      </td></tr></table>" "$HOME"/BirdNET-Pi/scripts/config.php
    sed -i "/\"success\"/i\      <br>" "$HOME"/BirdNET-Pi/scripts/config.php
    # Adapt birdnet_analysis.py - move_to_processed
    sed -i "/log.info('handle_reporting_queue done')/a\        os.remove(files.pop(0))" "$HOME"/BirdNET-Pi/scripts/birdnet_analysis.py
    sed -i "/log.info('handle_reporting_queue done')/a\    while len(files) > processed_size:" "$HOME"/BirdNET-Pi/scripts/birdnet_analysis.py
    sed -i "/log.info('handle_reporting_queue done')/a\    files.sort(key=os.path.getmtime)" "$HOME"/BirdNET-Pi/scripts/birdnet_analysis.py
    sed -i "/log.info('handle_reporting_queue done')/a\    files = glob.glob(os.path.join(processed_dir, '*'))" "$HOME"/BirdNET-Pi/scripts/birdnet_analysis.py
    sed -i "/log.info('handle_reporting_queue done')/a\    os.rename(file_name, os.path.join(processed_dir, os.path.basename(file_name)))" "$HOME"/BirdNET-Pi/scripts/birdnet_analysis.py
    sed -i "/log.info('handle_reporting_queue done')/a\    processed_dir = os.path.join(get_settings()['RECS_DIR'], 'Processed')" "$HOME"/BirdNET-Pi/scripts/birdnet_analysis.py
    sed -i "/log.info('handle_reporting_queue done')/a\def move_to_processed(file_name, processed_size):" "$HOME"/BirdNET-Pi/scripts/birdnet_analysis.py
    sed -i "/log.info('handle_reporting_queue done')/a\ " "$HOME"/BirdNET-Pi/scripts/birdnet_analysis.py
    # Adapt birdnet_analysis.py - get_processed_size
    sed -i "/log.info('handle_reporting_queue done')/a\        return 0" "$HOME"/BirdNET-Pi/scripts/birdnet_analysis.py
    sed -i "/log.info('handle_reporting_queue done')/a\    except (ValueError, TypeError):" "$HOME"/BirdNET-Pi/scripts/birdnet_analysis.py
    sed -i "/log.info('handle_reporting_queue done')/a\        return processed_size if isinstance(processed_size, int) else 0" "$HOME"/BirdNET-Pi/scripts/birdnet_analysis.py
    sed -i "/log.info('handle_reporting_queue done')/a\        processed_size = get_settings().getint('PROCESSED_SIZE')" "$HOME"/BirdNET-Pi/scripts/birdnet_analysis.py
    sed -i "/log.info('handle_reporting_queue done')/a\    try:" "$HOME"/BirdNET-Pi/scripts/birdnet_analysis.py
    sed -i "/log.info('handle_reporting_queue done')/a\def get_processed_size():" "$HOME"/BirdNET-Pi/scripts/birdnet_analysis.py
    sed -i "/log.info('handle_reporting_queue done')/a\ " "$HOME"/BirdNET-Pi/scripts/birdnet_analysis.py
    # Modify calls
    sed -i "/from subprocess import CalledProcessError/a\import glob" "$HOME"/BirdNET-Pi/scripts/birdnet_analysis.py
    sed -i "/from subprocess import CalledProcessError/a\import time" "$HOME"/BirdNET-Pi/scripts/birdnet_analysis.py
    # Modify main code
    sed -i "/os.remove(file.file_name)/i\            processed_size = get_processed_size()" "$HOME"/BirdNET-Pi/scripts/birdnet_analysis.py
    sed -i "/os.remove(file.file_name)/i\            if processed_size > 0:" "$HOME"/BirdNET-Pi/scripts/birdnet_analysis.py
    sed -i "/os.remove(file.file_name)/i\                move_to_processed(file.file_name, processed_size)" "$HOME"/BirdNET-Pi/scripts/birdnet_analysis.py
    sed -i "/os.remove(file.file_name)/i\            else:" "$HOME"/BirdNET-Pi/scripts/birdnet_analysis.py
    sed -i "/os.remove(file.file_name)/c\	            os.remove(file.file_name)" "$HOME"/BirdNET-Pi/scripts/birdnet_analysis.py
fi || true

echo " "
