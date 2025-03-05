#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

##################
# ALLOW RESTARTS #
##################

if [[ "${BASH_SOURCE[0]}" == /etc/cont-init.d/* ]]; then
    mkdir -p /etc/scripts-init
    sed -i "s|/etc/cont-init.d|/etc/scripts-init|g" /ha_entrypoint.sh
    sed -i "/ rm/d" /ha_entrypoint.sh
    cp "${BASH_SOURCE[0]}" /etc/scripts-init/
fi

################
# ADD FEATURES #
################

bashio::log.info "Adding optional features"

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

